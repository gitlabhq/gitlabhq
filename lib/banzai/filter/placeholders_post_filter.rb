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
      # `<span data-placeholder>` for text, or add `data-placeholder` to link or images.
      # This allows us to specifically search for those nodes.
      #
      # The syntax used is `%{PLACEHOLDER}`. Markdown processing ignores
      # this syntax, so even links with embedded placeholders will get
      # preserved.
      CSS = '[data-placeholder]'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze
      FILTER_ITEM_LIMIT = 100

      # Variables that can be replaced. We handle them all dynamically as there
      # is a _possibility_ that their value could change in the future.
      #
      # While it might be rare for something like `gitlab_server`, we
      # error on the side of safety right now. If needed in the future,
      # we can add a `PlaceholderPreFilter` that would insert the values in the
      # main pipeline. Downside of not caching is that
      # the value is not cached in the DB and has to be filled in on each display
      PLACEHOLDERS = {
        'gitlab_server' => ->(_context) { Gitlab.config.gitlab.host },
        'gitlab_pages_domain' => ->(_context) { Gitlab.config.pages.host },
        'project_path' => ->(context) do
          context[:project]&.full_path if Ability.allowed?(context[:current_user], :read_project, context[:project])
        end,
        'project_name' => ->(context) do
          context[:project]&.path if Ability.allowed?(context[:current_user], :read_project, context[:project])
        end,
        'project_id' => ->(context) do
          context[:project]&.id.to_s if Ability.allowed?(context[:current_user], :read_project, context[:project])
        end,
        'project_namespace' => ->(context) do
          if Ability.allowed?(context[:current_user], :read_project, context[:project])
            context[:project]&.project_namespace&.to_param
          end
        end,
        'project_title' => ->(context) do
          context[:project]&.title if Ability.allowed?(context[:current_user], :read_project, context[:project])
        end,
        'group_name' => ->(context) do
          group = context[:project]&.group || context[:group]
          group.name if Ability.allowed?(context[:current_user], :read_group, group)
        end,
        'default_branch' => ->(context) do
          if context[:project]&.repository_exists? &&
              Ability.allowed?(context[:current_user], :read_code, context[:project])
            context[:project]&.default_branch
          end
        end,
        'commit_sha' => ->(context) do
          if context[:project]&.repository_exists? &&
              Ability.allowed?(context[:current_user], :read_code, context[:project])
            context[:project]&.commit&.sha
          end
        end,
        'latest_tag' => ->(context) do
          if context[:project]&.repository_exists? &&
              Ability.allowed?(context[:current_user], :read_code, context[:project])
            TagsFinder.new(context[:project].repository, per_page: 1, sort: 'updated_desc')
              &.execute&.first&.name
          end
        end
      }.freeze

      PLACEHOLDERS_REGEX = /(#{PLACEHOLDERS.keys.join('|')})/

      def call
        return doc unless context[:project]&.markdown_placeholders_feature_flag_enabled? ||
          context[:group]&.markdown_placeholders_feature_flag_enabled?

        return doc if context[:disable_placeholders] || context[:broadcast_message_placeholders]

        doc.xpath(XPATH).each_with_index do |node, index|
          break if Banzai::Filter.filter_item_limit_exceeded?(index, limit: FILTER_ITEM_LIMIT)

          case node.name
          when 'span'
            replace_text_placeholders(node)
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

      def replace_text_placeholders(node)
        content = node.to_html
        placeholder = nil

        html_content =
          Gitlab::StringPlaceholderReplacer.replace_string_placeholders(content, PLACEHOLDERS_REGEX) do |arg|
            placeholder = arg if PLACEHOLDERS[arg]

            replace_placeholder_action(PLACEHOLDERS[arg])
          end

        if content != html_content
          node = node.replace(html_content).first
          node['data-placeholder'] = "%{#{placeholder}}" if placeholder
        end

        node
      end

      def replace_link_placeholders(node)
        href = link_href(node)

        new_href =
          Gitlab::StringPlaceholderReplacer.replace_string_placeholders(href, PLACEHOLDERS_REGEX) do |arg|
            # project_title doesn't belong in a url
            if arg != 'project_title'
              replace_placeholder_action(PLACEHOLDERS[arg])
            else
              "%{#{arg}}"
            end
          end

        node['href'] = new_href

        # the rich text editor needs to know what the original placeholders were
        node['data-canonical-src'] = href
        node['data-placeholder'] = href

        sanitize_link(node)
      end

      def replace_image_placeholders(node)
        url = img_src(node)

        new_url = Gitlab::StringPlaceholderReplacer.replace_string_placeholders(url, PLACEHOLDERS_REGEX) do |arg|
          # project_title doesn't belong in a url
          if arg != 'project_title'
            replace_placeholder_action(PLACEHOLDERS[arg])
          else
            "%{#{arg}}"
          end
        end

        adjust_image_node(node, url, new_url)

        node
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

        # the rich text editor needs to know what the original placeholders were
        node['data-canonical-src'] = url
        node['data-placeholder'] = url

        sanitize_link(node)

        if node['class']&.include?('lazy')
          node['data-src'] = node['src'] if node['src'].present?
          node['src'] = LazyImageTagHelper.placeholder_image
        end

        return unless node.parent&.name == 'a'

        # since we wrap images with a link, we need to update it's href
        node.parent['href'] = node['data-src'] || node['src']
      end

      def link_href(node)
        node.name == 'a' && node['href']
      end

      def img_src(node)
        node.name == 'img' && (node['data-canonical-src'] || node['data-src'] || node['src'])
      end

      # The action param represents the Proc to call in order to retrieve the value
      def replace_placeholder_action(action)
        replacement = action.call(context) || ''

        node = Banzai::Filter::SanitizationFilter.new(replacement).call
        CGI.escapeHTML(node.text)
      end

      def sanitize_link(node)
        Banzai::Filter::SanitizeLinkFilter.new(node).call
      end
    end
  end
end
