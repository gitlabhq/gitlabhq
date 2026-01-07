# frozen_string_literal: true

module Banzai
  module Filter
    # Replaces previously identified dynamic placeholders with current values.
    # By performing this as a post-processing filter, we can show current
    # information.
    class PlaceholdersPostFilter < HTML::Pipeline::Filter
      prepend Concerns::TimeoutFilterHandler
      prepend Concerns::PipelineTimingCheck

      # gitlab-glfm-markdown will detect possible placeholder values, and mark them with a
      # `<span data-placeholder>` for text, or add `data-placeholder` to links or images.
      # This allows us to specifically search for those nodes.
      #
      # The syntax used is `%{PLACEHOLDER}`. Markdown processing ignores
      # this syntax, so even links with embedded placeholders will get
      # preserved.
      CSS = '[data-placeholder]'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze
      FILTER_ITEM_LIMIT = 100

      ALLOWED_URI_CONTEXT_ALL = :all
      ALLOWED_URI_CONTEXT_ALL_BUT_HOST = :all_but_host

      # A `PlaceholderReplacer` is an object which knows how to generate a replacement
      # value for a given placeholder.
      #
      # It is initialized with a block, which generates the actual replacement value
      # given the filter context, as well as metadata which describes how replacements
      # are to be made in a URI context, such as a link href or image src:
      #
      # - allowed_uri_context describes which parts of a URI this placeholder can be
      #   invoked in.  It is either:
      #
      #   * ALLOWED_URI_CONTEXT_ALL, meaning it can appear in any part of a URI
      #     (host, path, query, or fragment); or,
      #   * ALLOWED_URI_CONTEXT_ALL_BUT_HOST, meaning it can appear in any part of
      #     a URI except host; namely path, query, or fragment.
      #
      #   If a placeholder is found in an unsupported context, it is left untouched.
      #
      # - uri_encode describes whether the replacement result should be
      #   percent-encoded when substituted into a URI.  This defaults to true, and
      #   should be overidden to false only when necessary for the placeholder to
      #   function as expected.
      #
      #   For example, "%{project_path}" will yield a replacement value like
      #   "gitlab-org/gitlab".  Percent-encoding this would yield
      #   "gitlab-org%2Fgitlab", which -- depending on the target service -- may not
      #   be desireable.  We may use `uri_encode: false` to allow substitutions like
      #   "http://%{gitlab_server}/%{project_path}" to work as expected.
      #
      #   On the other hand, "%{project_title}" and other free text-like inputs should
      #   always be kept as the default, `uri_encode: true`, otherwise the input can
      #   become interpreted incorrectly, and could potentially lead to XSS.
      #
      #   When we disable `uri_encode` for any given replacer, we give a rationale to
      #   help vet the correctness of the decision over time.
      #
      class PlaceholderReplacer
        def initialize(allowed_uri_context, uri_encode: true, &block)
          case allowed_uri_context
          when ALLOWED_URI_CONTEXT_ALL
            unless uri_encode
              raise ArgumentError,
                "combining ALLOWED_URI_CONTEXT_ALL and uri_encode: false is a security risk"
            end
          when ALLOWED_URI_CONTEXT_ALL_BUT_HOST
            # No-op.
          else
            raise ArgumentError, 'invalid allowed_uri_context value; must be ALLOWED_URI_CONTEXT_ALL or ' \
              'ALLOWED_URI_CONTEXT_ALL_BUT_HOST'
          end

          @allowed_uri_context = allowed_uri_context
          @uri_encode = uri_encode
          @block = block
        end

        attr_reader :allowed_uri_context, :uri_encode, :block

        def generate(context, in_uri_component:)
          return block.call(context) || '' unless in_uri_component

          # Only generate in permissible contexts.
          # If not permitted, we return nil, which signals no replacement is to be made at all
          # (as opposed to '', which replaces with the empty string).
          if allowed_uri_context == ALLOWED_URI_CONTEXT_ALL ||
              (allowed_uri_context == ALLOWED_URI_CONTEXT_ALL_BUT_HOST && in_uri_component != :host)
            maybe_encode(block.call(context) || '')
          end
        end

        private

        def maybe_encode(result)
          uri_encode ? CGI.escapeURIComponent(result) : result
        end
      end

      # Variables that can be replaced. We handle them all dynamically in post-process
      # as the values can change over time.
      #
      # All placeholder replacements yield text, not HTML, and must be escaped or set
      # as a text node's content.
      #
      # See PlaceholderReplacer for documentation on the metadata of each.
      PLACEHOLDER_REPLACERS = {
        'gitlab_server' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL) do
          Gitlab.config.gitlab.host
        end,
        'gitlab_pages_domain' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL) do
          Gitlab.config.pages.host
        end,
        'project_path' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST, uri_encode: false) do |context|
          # Rationale for `uri_encode: false`: the path is to be explicitly expandable, as many services
          # will generate URLs including a namespaced path for end-users.
          context[:project]&.full_path if Ability.allowed?(context[:current_user], :read_project, context[:project])
        end,
        'project_name' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST) do |context|
          context[:project]&.path if Ability.allowed?(context[:current_user], :read_project, context[:project])
        end,
        'project_id' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST) do |context|
          context[:project]&.id.to_s if Ability.allowed?(context[:current_user], :read_project, context[:project])
        end,
        'project_namespace' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST) do |context|
          if Ability.allowed?(context[:current_user], :read_project, context[:project])
            context[:project]&.project_namespace&.to_param
          end
        end,
        'project_title' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST) do |context|
          context[:project]&.title if Ability.allowed?(context[:current_user], :read_project, context[:project])
        end,
        'group_name' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST) do |context|
          group = context[:project]&.group || context[:group]
          group.name if Ability.allowed?(context[:current_user], :read_group, group)
        end,
        'default_branch' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST, uri_encode: false) do |context|
          # Rationale for `uri_encode: false`: GitLab displays URLs like
          #   http://gdk.test:3000/root/comrak/-/tree/kiv/dev
          # where "kiv/dev" is a branch name.  (In practice, as of writing, they generate a 404 when used!)
          # To support this kind of expansion, we must not percent-encode the branch name.
          if context[:project]&.repository_exists? &&
              Ability.allowed?(context[:current_user], :read_code, context[:project])
            context[:project]&.default_branch
          end
        end,
        'current_ref' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST) do |context|
          if context[:project]&.repository_exists? &&
              Ability.allowed?(context[:current_user], :read_code, context[:project])
            context[:ref]
          end
        end,
        'commit_sha' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST) do |context|
          if context[:project]&.repository_exists? &&
              Ability.allowed?(context[:current_user], :read_code, context[:project])
            context[:project]&.commit&.sha
          end
        end,
        'latest_tag' => PlaceholderReplacer.new(ALLOWED_URI_CONTEXT_ALL_BUT_HOST, uri_encode: false) do |context|
          if context[:project]&.repository_exists? &&
              Ability.allowed?(context[:current_user], :read_code, context[:project])
            # Rationale for `uri_encode: false`: GitLab uses URLs like
            #   http://gdk.test:3000/root/comrak/-/tree/a/b/c
            # where "a/b/c" is a tag name.  (These actually work, unlike branches.)
            # To support this kind of expansion, we must not percent-encode the tag name.
            TagsFinder.new(context[:project].repository, per_page: 1, sort: 'updated_desc')
              &.execute&.first&.name
          end
        end
      }.freeze

      PLACEHOLDERS_REGEX = /(#{PLACEHOLDER_REPLACERS.keys.map { |p| Regexp.escape(p) }.join('|')})/
      PLACEHOLDERS_FULL_ANCHORED_REGEX = /\A%\{#{PLACEHOLDERS_REGEX}}\z/

      def call
        return doc unless context[:project]&.markdown_placeholders_feature_flag_enabled? ||
          context[:group]&.markdown_placeholders_feature_flag_enabled?

        return doc if context[:disable_placeholders] || context[:broadcast_message_placeholders]

        doc.xpath(XPATH).each_with_index do |node, index|
          break if Banzai::Filter.filter_item_limit_exceeded?(index, limit: FILTER_ITEM_LIMIT)

          case node.name
          when 'span'
            replace_span_placeholder(node)
          when 'a'
            replace_link_placeholders(node)
          when 'img'
            replace_image_placeholders(node)
          else
            next
          end
        end

        doc
      end

      private

      def replace_span_placeholder(node)
        # The <span>'s only content is the placeholder. If this isn't the case, the
        # `data-placeholder` was added in error/not by our parser, we'll fail to match
        # the content, and leave it alone.  We should not do any replacement that isn't
        # a full match of the text content.
        #
        # Note that this function was once the site of an XSS vector, and great care
        # must be taken to ensure no text is accidentally promoted to HTML.  We do not
        # do anything about `node.to_html` or `node.inner_html` on purpose.
        #
        # `node.content` gives text and `node.content=` sets text.
        # Don't mix the use of `#content` and `#inner_html` indiscriminately.
        match_data = PLACEHOLDERS_FULL_ANCHORED_REGEX.match(node.content)
        return unless match_data

        placeholder_name = match_data[1]
        replacer = PLACEHOLDER_REPLACERS[placeholder_name]

        node['data-placeholder'] = node.content
        node.content = replacer.generate(context, in_uri_component: false)
      end

      def replace_link_placeholders(node, limit: 0)
        href = link_href(node)

        node['href'] = replace_placeholders_within_url_attr(href, limit:)
        node['data-canonical-src'] = href
        node['data-placeholder'] = href

        sanitize_link(node)
      end

      def replace_image_placeholders(node, limit: 0)
        url = img_src(node)

        new_url = replace_placeholders_within_url_attr(url, limit:)

        adjust_image_node(node, url, new_url)
      end

      # Do placeholder replacement within a URL as found in an HTML attribute.
      #
      # Takes the HTML attribute value as an argument; this should be the DOM value,
      # i.e. what Nokogiri gives you when you say node['href'] or node['src'].
      # In particular, this means there will be no HTML entities that aren't actually
      # spelled out in the text.
      #
      # There will still be URI encoded characters, which look like this: %5B.
      # In particular, if the user enters "[hello](%{something})", the href will be
      # "%%7Bsomething%7D"; we need to interpret the percent-decodes to get "%{something}".
      # We can't do this across the string, however, as there are other characters which
      # (a) have special meaning in the context of a URI, and (b) can be percent-encoded
      # to avoid that, such as "#" (%23), "?" (%3f), and "/" (%2f).
      #
      # Accordingly, we match any of the following within a URI attribute:
      #
      # - "%{...}"
      # - "%%7B...%7D" (case-insensitive; emitted by most CommonMark parsers)
      # - "%25%7B...%7D" (case-insensitive; canonical valid encoding of "%{...}")
      #
      # Replacement values are percent-encoded where necessary according to the actual
      # placeholder type -- see PlaceholderReplacer documentation comment for more.
      # We do this regardless of the format of the original match, as a URL may also have
      # non-percent-encoded "{" and "}" as part of a placeholder, such as when entered
      # directly in a href in inline HTML in Markdown, such as
      # "<a href='https://example.com/%{project_path}' data-placeholder>".
      #
      # Gives the new DOM value for replacement.
      def replace_placeholders_within_url_attr(attr_value, limit:)
        uri = Addressable::URI.parse(attr_value)

        uri.host = replace_placeholders_within_uri_component(:host, uri.host, limit:)

        # Treat the path component as if it were the host when doing replacements on mailto:
        # URLs, as they effectively contain the host: "mailto:hello@example.com" has a host of
        # nil, and a path of "hello@example.com".
        path_component = uri.scheme == 'mailto' ? :host : :path
        uri.path = replace_placeholders_within_uri_component(path_component, uri.path, limit:)

        uri.query = replace_placeholders_within_uri_component(:query, uri.query, limit:)
        uri.fragment = replace_placeholders_within_uri_component(:fragment, uri.fragment, limit:)

        uri.to_s
      end

      def replace_placeholders_within_uri_component(component, value, limit:)
        Gitlab::StringPlaceholderReplacer.replace_string_placeholders(value, PLACEHOLDERS_REGEX,
          in_uri: true, limit: limit) do |placeholder_name|
          replacer = PLACEHOLDER_REPLACERS[placeholder_name]

          replacer.generate(context, in_uri_component: component)
        end
      end

      def adjust_image_node(node, url, new_url)
        if node['data-canonical-src']
          # most likely generated by the asset proxy
          node['src'] = new_url
          node.remove_attribute('data-canonical-src')
          node.remove_attribute('data-src')

          asset = Banzai::Filter::AssetProxyFilter.new(node.to_html, context).call
          asset_node = asset&.children&.first

          node['src'] = asset_node['src'] if asset_node && asset_node['data-canonical-src']
        else
          node['src'] = new_url
        end

        node['data-src'] = new_url
        node['data-canonical-src'] = url
        node['data-placeholder'] = url

        # At this point:
        #
        # * data-canonical-src and data-placeholder contain the original entered URL, with placeholder syntax intact.
        #   * data-canonical-src is usually put in place by AssetProxyFilter.
        # * data-src contains the URL with all replacements made.
        #   * data-src is usually put in place by ImageLazyLoadFilter.
        # * src contains the URL with replacements made ...
        #   * ... put through the AssetProxyFilter, if the original appeared to be, and if the AssetProxyFilter made
        #     any changes.

        sanitize_link(node)

        if node['class']&.include?('lazy')
          # Looks like ImageLazyLoadFilter ran on the original. Perform the same transformation it
          # does on the URLs; copy src (which may have been changed by the AssetProxyFilter) to data-src,
          # and replace src with the placeholder image.
          node['data-src'] = node['src'] if node['src'].present?
          node['src'] = LazyImageTagHelper.placeholder_image
        end

        # At this point, src will contain either:
        # * the new URL, if neither AssetProxyFilter nor ImageLazyLoadFilter applied;
        # * the new asset proxy URL, if AssetProxyFilter but not ImageLazyLoadFilter applied;
        # * the placeholder image, if ImageLazyLoadFilter applied.
        #
        # This is what the browser will load first.
        #
        # data-src will contain the new URL, or the new asset proxy URL.  It's always the actual
        # image to be served, after any lazy loading logic is done.
        #
        # data-canonical-src will always contain the original entered URL, before any replacements are made.
        #
        # Note that, as-is, if the asset proxy is enabled, we don't preserve the new URL with replacements made
        # without the asset proxy transformation anywhere.

        return unless node.parent&.name == 'a'

        # Since we wrap images with a link, we need to update the link href too;
        # use data-src, as it's the actual target (possibly asset proxied).
        node.parent['href'] = node['data-src']
      end

      def link_href(node)
        node.name == 'a' && node['href']
      end

      def img_src(node)
        # AssetProxyFilter puts the src in data-canonical-src and updates src to the proxied URL.
        # Later, ImageLazyLoadFilter puts the src in data-src and updates src to the placeholder image.
        # This order of attributes ensures we get the original entered src whether both, one,
        # or none of the above are enabled/run on any particular <img> node.
        node.name == 'img' && (node['data-canonical-src'] || node['data-src'] || node['src'])
      end

      def sanitize_link(node)
        Banzai::Filter::SanitizeLinkFilter.new(node).call
      end
    end
  end
end
