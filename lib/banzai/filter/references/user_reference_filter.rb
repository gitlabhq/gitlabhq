# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces user or group references with links.
      #
      # A special `@all` reference is also supported.
      class UserReferenceFilter < ReferenceFilter
        include Gitlab::Utils::StrongMemoize

        self.reference_type = :user
        self.object_class   = User

        # Public: Find `@user` user references in text
        #
        #   references_in(text) do |match_text, username|
        #     "<a href=...>@#{user}</a>"
        #   end
        #
        # text - String text to search.
        #
        # Yields the String match text, and the String user name.
        #
        # Returns a HTML String with replacements made, or nil if no replacements were made.
        #
        # See ReferenceFilter#references_in for a detailed discussion.
        def references_in(text, pattern = object_reference_pattern)
          replace_references_in_text_with_html(Gitlab::Utils::Gsub.gsub_with_limit(text, pattern,
            limit: Banzai::Filter::FILTER_ITEM_LIMIT)) do |match_data|
            yield match_data[0], match_data[:user]
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
        # link_content_html - Original HTML content of the link being replaced.
        #
        # Returns a HTML String with `@user` references replaced with links. All links
        # have `gfm` and `gfm-project_member` class names attached for styling.
        #
        # Returns nil if no replacements were made.
        def object_link_filter(text, pattern, link_content_html: nil, link_reference: false)
          references_in(text, pattern) do |match_text, username|
            if Feature.disabled?(:disable_all_mention) && username == 'all' && !skip_project_check?
              link_to_all(match_text:, link_content_html:)
            else
              cached_call(:banzai_url_for_object, match_text, path: [User, username]) do
                # order is important: per-organization usernames should be checked before global namespace
                if org_user_detail = org_user_details[username.downcase]
                  link_to_org_user_detail(org_user_detail, match_text:, link_content_html:)
                elsif namespace = namespaces[username.downcase]
                  link_to_namespace(namespace, match_text:, link_content_html:)
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
          Namespace.preload(:owner, :route)
                   .where_full_path_in(usernames)
                   .index_by(&:full_path)
                   .transform_keys(&:downcase)
        end
        strong_memoize_attr :namespaces

        # check for users that have an aliased name within an organization,
        # for example the bot users created by Users::Internal
        def org_user_details
          return {} unless Feature.enabled?(:organization_users_internal, organization)

          Organizations::OrganizationUserDetail.for_references
                                               .in_organization(organization)
                                               .with_usernames(usernames)
                                               .index_by(&:username)
                                               .transform_keys(&:downcase)
        end
        strong_memoize_attr :org_user_details

        # Returns all usernames referenced in the current document.
        def usernames
          refs = Set.new

          ref_pattern = User.reference_pattern
          ref_pattern_anchor = /\A#{ref_pattern}\z/

          nodes.each do |node|
            node.content.scan(ref_pattern) do
              refs << $~[:user]
            end

            yield_valid_link(node) do |link|
              refs << $~[:user] if link.match(ref_pattern_anchor)
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

        def link_to_all(match_text:, link_content_html:)
          author = context[:author]

          if author && !team_member?(author)
            link_content_html
          else
            parent_url(author, match_text:, link_content_html:)
          end
        end

        def link_to_namespace(namespace, match_text:, link_content_html:)
          if namespace.is_a?(Group)
            link_to_group(namespace.full_path, namespace, match_text:, link_content_html:)
          else
            link_to_user(namespace.path, namespace, match_text:, link_content_html:)
          end
        end

        def link_to_group(group, namespace, match_text:, link_content_html:)
          url = urls.group_url(group, only_path: context[:only_path])
          data_attributes = data_attributes_for(match_text, link_content_html, group: namespace.id)
          html_content = link_content_html || CGI.escapeHTML(Group.reference_prefix + group)

          link_tag(url, data_attributes, html_content, namespace.full_name)
        end

        def link_to_user(user, namespace, match_text:, link_content_html:)
          url = urls.user_url(user, only_path: context[:only_path])
          data_attributes = data_attributes_for(match_text, link_content_html, user: namespace.owner_id)
          html_content = link_content_html || CGI.escapeHTML(User.reference_prefix + user)

          link_tag(url, data_attributes, html_content, namespace.owner_name)
        end

        def link_to_org_user_detail(org_user_detail, match_text:, link_content_html:)
          user = org_user_detail.user
          url = urls.user_url(user, only_path: context[:only_path])
          data_attributes = data_attributes_for(match_text, link_content_html, user: user.id)
          html_content = link_content_html || CGI.escapeHTML(org_user_detail.to_reference)

          link_tag(url, data_attributes, html_content, org_user_detail.username)
        end

        def link_tag(url, data_attributes, link_content_html, title)
          data = data_attribute(data_attributes)

          write_opening_tag("a", {
            "href" => url,
            "title" => title,
            "class" => link_class,
            **data
          }) << link_content_html << "</a>"
        end

        def organization
          parent&.organization ||
            context[:author]&.organizations&.first ||
            Organizations::Organization.first
        end
        strong_memoize_attr :organization

        def parent
          context[:project] || context[:group]
        end

        def parent_group?
          parent.is_a?(Group)
        end

        def team_member?(user)
          parent.member?(user)
        end

        def parent_url(author, match_text:, link_content_html:)
          if parent_group?
            url = urls.group_url(parent, only_path: context[:only_path])
            data_attributes = data_attributes_for(match_text, link_content_html, group: group.id,
              author: author.try(:id))
          else
            url = urls.project_url(parent, only_path: context[:only_path])
            data_attributes = data_attributes_for(match_text, link_content_html, project: project.id,
              author: author.try(:id))
          end

          html_content = link_content_html || CGI.escapeHTML(User.reference_prefix + 'all')
          link_tag(url, data_attributes, html_content, 'All Project and Group Members')
        end
      end
    end
  end
end
