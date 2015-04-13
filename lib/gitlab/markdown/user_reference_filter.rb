require 'html/pipeline'

module Gitlab
  module Markdown
    # HTML filter that replaces user or group references with links. References
    # within <pre>, <code>, <a>, and <style> elements are ignored.
    #
    # A special `@all` reference is also supported.
    #
    # Context options:
    #   :project (required) - Current project.
    #   :reference_class    - Custom CSS class added to reference links.
    #   :only_path          - Generate path-only links.
    #
    class UserReferenceFilter < HTML::Pipeline::Filter
      # Public: Find `@user` user references in text
      #
      #   UserReferenceFilter.references_in(text) do |match, username|
      #     "<a href=...>@#{user}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, and the String user name.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(USER_PATTERN) do |match|
          yield match, $~[:user]
        end
      end

      # Pattern used to extract `@user` user references from text
      USER_PATTERN = /@(?<user>#{Gitlab::Regex::NAMESPACE_REGEX_STR})/

      # Don't look for references in text nodes that are children of these
      # elements.
      IGNORE_PARENTS = %w(pre code a style).to_set

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if project.nil?
          next unless content.match(USER_PATTERN)
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = user_link_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      def validate
        needs :project
      end

      # Replace `@user` user references in text with links to the referenced
      # user's profile page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with `@user` references replaced with links. All links
      # have `gfm` and `gfm-project_member` class names attached for styling.
      def user_link_filter(text)
        project = context[:project]

        self.class.references_in(text) do |match, user|
          klass = "gfm gfm-project_member #{context[:reference_class]}".strip

          if user == 'all'
            url = link_to_all(project)

            %(<a href="#{url}" class="#{klass}">@#{user}</a>)
          elsif namespace = Namespace.find_by(path: user)
            if namespace.is_a?(Group)
              if user_can_read_group?(namespace)
                url = group_url(user, only_path: context[:only_path])
                %(<a href="#{url}" class="#{klass}">@#{user}</a>)
              else
                match
              end
            else
              url = user_url(user, only_path: context[:only_path])
              %(<a href="#{url}" class="#{klass}">@#{user}</a>)
            end
          else
            match
          end
        end
      end

      def project
        context[:project]
      end

      # TODO (rspeicher): Cleanup
      def group_url(*args)
        h = Rails.application.routes.url_helpers
        h.group_url(*args)
      end

      # TODO (rspeicher): Cleanup
      def user_url(*args)
        h = Rails.application.routes.url_helpers
        h.user_url(*args)
      end

      # TODO (rspeicher): Cleanup
      def link_to_all(project)
        h = Rails.application.routes.url_helpers
        h.namespace_project_url(project.namespace, project,
                                only_path: context[:only_path])
      end

      def user_can_read_group?(group)
        return false if context[:current_user].blank?
        Ability.abilities.allowed?(context[:current_user], :read_group, group)
      end
    end
  end
end
