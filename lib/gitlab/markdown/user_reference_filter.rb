module Gitlab
  module Markdown
    # HTML filter that replaces user or group references with links.
    #
    # A special `@all` reference is also supported.
    class UserReferenceFilter < ReferenceFilter
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

      def call
        replace_text_nodes_matching(USER_PATTERN) do |content|
          user_link_filter(content)
        end
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
          klass = reference_class(:project_member)

          if user == 'all'
            url = link_to_all(project)

            %(<a href="#{url}" class="#{klass}">@#{user}</a>)
          elsif namespace = Namespace.find_by(path: user)
            if namespace.is_a?(Group)
              if user_can_reference_group?(namespace)
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

      private

      def urls
        Rails.application.routes.url_helpers
      end

      def group_url(*args)
        urls.group_url(*args)
      end

      def user_url(*args)
        urls.user_url(*args)
      end

      def link_to_all(project)
        urls.namespace_project_url(project.namespace, project,
                                   only_path: context[:only_path])
      end

      def user_can_reference_group?(group)
        Ability.abilities.allowed?(context[:current_user], :read_group, group)
      end
    end
  end
end
