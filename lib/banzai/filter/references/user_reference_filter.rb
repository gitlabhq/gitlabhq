# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces user or group references with links.
      #
      # A special `@all` reference is also supported.
      class UserReferenceFilter < ReferenceFilter
        self.reference_type = :user
        self.object_class   = User

        # Public: Find `@user` user references in text
        #
        #   references_in(text) do |match, username|
        #     "<a href=...>@#{user}</a>"
        #   end
        #
        # text - String text to search.
        #
        # Yields the String match, and the String user name.
        #
        # Returns a String replaced with the return of the block.
        def references_in(text, pattern = object_reference_pattern)
          text.gsub(pattern) do |match|
            yield match, $~[:user]
          end
        end

        def call
          return doc if project.nil? && group.nil? && !skip_project_check?

          super
        end

        private

        # Replace `@user` user references in text with links to the referenced
        # user's profile page.
        #
        # text - String text to replace references in.
        # link_content - Original content of the link being replaced.
        #
        # Returns a String with `@user` references replaced with links. All links
        # have `gfm` and `gfm-project_member` class names attached for styling.
        def object_link_filter(text, pattern, link_content: nil, link_reference: false)
          references_in(text, pattern) do |match, username|
            if username == 'all' && !skip_project_check?
              link_to_all(link_content: link_content)
            else
              cached_call(:banzai_url_for_object, match, path: [User, username.downcase]) do
                if namespace = namespaces[username.downcase]
                  link_to_namespace(namespace, link_content: link_content) || match
                else
                  match
                end
              end
            end
          end
        end

        # Returns a Hash containing all Namespace objects for the username
        # references in the current document.
        #
        # The keys of this Hash are the namespace paths, the values the
        # corresponding Namespace objects.
        def namespaces
          @namespaces ||= Namespace.eager_load(:owner, :route)
                                   .where_full_path_in(usernames)
                                   .index_by(&:full_path)
                                   .transform_keys(&:downcase)
        end

        # Returns all usernames referenced in the current document.
        def usernames
          refs = Set.new

          nodes.each do |node|
            node.to_html.scan(User.reference_pattern) do
              refs << $~[:user]
            end
          end

          refs.to_a
        end

        def urls
          Gitlab::Routing.url_helpers
        end

        def link_class
          [reference_class(:project_member, tooltip: false), "js-user-link"].join(" ")
        end

        def link_to_all(link_content: nil)
          author = context[:author]

          if author && !team_member?(author)
            link_content
          else
            parent_url(link_content, author)
          end
        end

        def link_to_namespace(namespace, link_content: nil)
          if namespace.is_a?(Group)
            link_to_group(namespace.full_path, namespace, link_content: link_content)
          else
            link_to_user(namespace.path, namespace, link_content: link_content)
          end
        end

        def link_to_group(group, namespace, link_content: nil)
          url = urls.group_url(group, only_path: context[:only_path])
          data = data_attribute(group: namespace.id)
          content = link_content || Group.reference_prefix + group

          link_tag(url, data, content, namespace.full_name)
        end

        def link_to_user(user, namespace, link_content: nil)
          url = urls.user_url(user, only_path: context[:only_path])
          data = data_attribute(user: namespace.owner_id)
          content = link_content || User.reference_prefix + user

          link_tag(url, data, content, namespace.owner_name)
        end

        def link_tag(url, data, link_content, title)
          %(<a href="#{url}" #{data} class="#{link_class}" title="#{escape_once(title)}">#{link_content}</a>)
        end

        def parent
          context[:project] || context[:group]
        end

        def parent_group?
          parent.is_a?(Group)
        end

        def team_member?(user)
          if parent_group?
            parent.member?(user)
          else
            parent.team.member?(user)
          end
        end

        def parent_url(link_content, author)
          if parent_group?
            url = urls.group_url(parent, only_path: context[:only_path])
            data = data_attribute(group: group.id, author: author.try(:id))
          else
            url = urls.project_url(parent, only_path: context[:only_path])
            data = data_attribute(project: project.id, author: author.try(:id))
          end

          content = link_content || User.reference_prefix + 'all'
          link_tag(url, data, content, 'All Project and Group Members')
        end
      end
    end
  end
end
