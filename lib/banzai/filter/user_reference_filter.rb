module Banzai
  module Filter
    # HTML filter that replaces user or group references with links.
    #
    # A special `@all` reference is also supported.
    class UserReferenceFilter < ReferenceFilter
      self.reference_type = :user

      def self.reference_pattern
        User.reference_pattern
      end

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
        text.gsub(reference_pattern) do |match|
          yield match, $~[reference_type]
        end
      end

      def call
        return doc if project.nil? && !skip_project_check?

        ref_pattern = self.class.reference_pattern
        ref_pattern_start = /\A#{ref_pattern}\z/

        nodes.each do |node|
          if text_node?(node)
            replace_text_when_pattern_matches(node, ref_pattern) do |content|
              user_link_filter(content)
            end
          elsif element_node?(node)
            yield_valid_link(node) do |link, inner_html|
              if link =~ ref_pattern_start
                replace_link_node_with_href(node, link) do
                  user_link_filter(link, link_content: inner_html)
                end
              end
            end
          end
        end

        doc
      end

      # Replace `@user` user references in text with links to the referenced
      # user's profile page.
      #
      # text - String text to replace references in.
      # link_content - Original content of the link being replaced.
      #
      # Returns a String with `@user` references replaced with links. All links
      # have `gfm` and `gfm-project_member` class names attached for styling.
      def user_link_filter(text, link_content: nil)
        self.class.references_in(text) do |match, username|
          if username == 'all' && !skip_project_check?
            link_to_all(link_content: link_content)
          elsif user = users[username]
            link_to_user(user, link_content: link_content) || match
          else
            match
          end
        end
      end

      # Returns a Hash containing all User objects for the username
      # references in the current document.
      #
      # The keys of this Hash are the user paths, the values the
      # corresponding User objects.
      def users
        @users ||=
          User.where(username: usernames).each_with_object({}) do |row, hash|
            hash[row.username] = row
          end
      end

      # Returns all usernames referenced in the current document.
      def usernames
        refs = Set.new

        nodes.each do |node|
          node.to_html.scan(self.class.reference_pattern) do
            refs << $~[self.class.reference_type]
          end
        end

        refs.to_a
      end

      private

      def urls
        Gitlab::Routing.url_helpers
      end

      def link_class
        reference_class(:project_member)
      end

      def link_to_all(link_content: nil)
        project = context[:project]
        author = context[:author]

        if author && !project.team.member?(author)
          link_content
        else
          url = urls.namespace_project_url(project.namespace, project,
                                           only_path: context[:only_path])

          data = data_attribute(project: project.id, author: author.try(:id))
          content = link_content || User.reference_prefix + 'all'

          link_tag(url, data, content, 'All Project and Group Members')
        end
      end

      def link_to_user(user, link_content: nil)
        url = urls.user_url(user, only_path: context[:only_path])
        data = data_attribute(user: user.id)
        content = link_content || User.reference_prefix + user.username

        link_tag(url, data, content, user.name)
      end

      def link_tag(url, data, link_content, title)
        %(<a href="#{url}" #{data} class="#{link_class}" title="#{escape_once(title)}">#{link_content}</a>)
      end
    end
  end
end
