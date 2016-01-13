module Banzai
  module Filter
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
        text.gsub(User.reference_pattern) do |match|
          yield match, $~[:user]
        end
      end

      def self.referenced_by(node)
        if node.has_attribute?('data-group')
          group = Group.find(node.attr('data-group')) rescue nil
          return unless group

          { user: group.users }
        elsif node.has_attribute?('data-user')
          { user: LazyReference.new(User, node.attr('data-user')) }
        elsif node.has_attribute?('data-project')
          project = Project.find(node.attr('data-project')) rescue nil
          return unless project

          { user: project.team.members.flatten }
        end
      end

      def self.user_can_see_reference?(user, node, context)
        if node.has_attribute?('data-group')
          group = Group.find(node.attr('data-group')) rescue nil
          Ability.abilities.allowed?(user, :read_group, group)
        else
          super
        end
      end

      def self.user_can_reference?(user, node, context)
        # Only team members can reference `@all`
        if node.has_attribute?('data-project')
          project = Project.find(node.attr('data-project')) rescue nil
          return false unless project

          user && project.team.member?(user)
        else
          super
        end
      end

      def call
        replace_text_nodes_matching(User.reference_pattern) do |content|
          user_link_filter(content)
        end

        replace_link_nodes_with_href(User.reference_pattern) do |link, text|
          user_link_filter(link, link_text: text)
        end
      end

      # Replace `@user` user references in text with links to the referenced
      # user's profile page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with `@user` references replaced with links. All links
      # have `gfm` and `gfm-project_member` class names attached for styling.
      def user_link_filter(text, link_text: nil)
        self.class.references_in(text) do |match, username|
          if username == 'all'
            link_to_all(link_text: link_text)
          elsif namespace = Namespace.find_by(path: username)
            link_to_namespace(namespace, link_text: link_text) || match
          else
            match
          end
        end
      end

      private

      def urls
        Gitlab::Application.routes.url_helpers
      end

      def link_class
        reference_class(:project_member)
      end

      def link_to_all(link_text: nil)
        project = context[:project]
        url = urls.namespace_project_url(project.namespace, project,
                                         only_path: context[:only_path])
        data = data_attribute(project: project.id)
        text = link_text || User.reference_prefix + 'all'

        link_tag(url, data, text)
      end

      def link_to_namespace(namespace, link_text: nil)
        if namespace.is_a?(Group)
          link_to_group(namespace.path, namespace, link_text: link_text)
        else
          link_to_user(namespace.path, namespace, link_text: link_text)
        end
      end

      def link_to_group(group, namespace, link_text: nil)
        url = urls.group_url(group, only_path: context[:only_path])
        data = data_attribute(group: namespace.id)
        text = link_text || Group.reference_prefix + group

        link_tag(url, data, text)
      end

      def link_to_user(user, namespace, link_text: nil)
        url = urls.user_url(user, only_path: context[:only_path])
        data = data_attribute(user: namespace.owner_id)
        text = link_text || User.reference_prefix + user

        link_tag(url, data, text)
      end

      def link_tag(url, data, text)
        %(<a href="#{url}" #{data} class="#{link_class}">#{escape_once(text)}</a>)
      end
    end
  end
end
