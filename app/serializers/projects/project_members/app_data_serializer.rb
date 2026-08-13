# frozen_string_literal: true

module Projects
  module ProjectMembers
    # Assembles the structured data payloads consumed by the members Vue app on
    # the project members page, following the `JiraConnect::AppDataSerializer`
    # pattern.
    #
    # Extracted from `Projects::ProjectMembersHelper` so that payload assembly
    # (permission checks, serializers, pagination and route generation) is
    # unit-testable without a view context, and so the controller's JSON
    # response can call a first-class object instead of reaching through
    # `helpers.`. HTML-rendering helpers remain in the helper.
    class AppDataSerializer
      include Gitlab::Routing
      include Gitlab::Allowable

      def initialize(project, current_user:, members: nil, direct_members_filter_params: {})
        @project = project
        @current_user = current_user
        @members = members
        @direct_members_filter_params = direct_members_filter_params
      end

      def app_data(
        invited:, links:, access_requests:, pending_members_count: # rubocop:disable Lint/UnusedMethodArgument -- Argument used in EE
      )
        {
          user: list_data(members, { param_name: :page, params: { search_groups: nil } }),
          direct_members: direct_members_lazy_data,
          group: group_links_list_data(links),
          invite: list_data(invited.nil? ? [] : invited),
          access_request: list_data(access_requests.nil? ? [] : access_requests),
          source_id: project.id,
          # rubocop:disable Gitlab/Authz/PermissionCheck -- Checks moved verbatim from
          # Projects::ProjectMembersHelper; migrating them to granular permissions is
          # out of scope for this refactor.
          can_manage_members: can?(current_user, :admin_project_member, project),
          can_manage_access_requests: can?(current_user, :admin_member_access_request, project),
          # rubocop:enable Gitlab/Authz/PermissionCheck
          group_name: project.group&.name,
          group_path: project.group&.full_path,
          project_path: project.full_path,
          can_approve_access_requests: true, # true for CE, overridden in EE
          available_roles: available_roles
        }
      end

      def list_data(scoped_members = members, pagination = {})
        {
          members: members_serialized(scoped_members),
          pagination: members_pagination_data(scoped_members, pagination),
          member_path: project_project_member_path(project, ':id')
        }
      end

      private

      attr_reader :project, :current_user, :members, :direct_members_filter_params

      # The Direct members tab is lazy: it is seeded empty and fetches its rows from
      # `members_path` (the members index JSON endpoint) when the tab is activated.
      # This keeps the direct members rows/preloader off the initial page load.
      #
      # The total count is seeded via a single cheap COUNT so the tab count badge is
      # accurate immediately, without loading (and preloading) all member rows.
      def direct_members_lazy_data
        seed = Kaminari.paginate_array([], total_count: direct_members_count)

        {
          members: [],
          pagination: members_pagination_data(seed, { param_name: :direct_members_page }),
          member_path: project_project_member_path(project, ':id'),
          members_path: project_project_members_path(project, format: :json)
        }
      end

      # Derive the seeded count from the same finder that produces the tab's rows
      # (see `Projects::ProjectMembersController#non_invited_direct_members`) so the
      # badge count and the loaded list share a single source of truth for "what is
      # a direct member". Using the association COUNT here would be a second, silently
      # divergent definition. The same search/max_role filter params are applied so a
      # seed served for a filtered URL matches the filtered rows the fetch will load.
      #
      # Kaminari's `total_count` is used (rather than a bare `count`) because it is
      # the same value `members_pagination_data` reports for the fetched list, and it
      # counts correctly when `Member.search` adds custom SELECT/ORDER expressions.
      def direct_members_count
        MembersFinder
          .new(project, current_user, params: direct_members_filter_params)
          .execute(include_relations: [:direct])
          .non_invite
          .page(1)
          .total_count
      end

      def group_links_list_data(links)
        group_link_members = project_group_links_serialized(links.project_links)
        group_link_members += group_group_links_serialized(links.group_links)

        {
          members: group_link_members,
          pagination: members_pagination_data(links, { param_name: :page }),
          member_path: project_group_link_path(project, ':id')
        }
      end

      # rubocop:disable CodeReuse/Serializer -- This class is the composition
      # layer that assembles the member serializers into the members app
      # payload (see JiraConnect::AppDataSerializer for the same pattern).
      def members_serialized(collection)
        MemberSerializer
          .new
          .represent(collection, { current_user: current_user, group: project.group, source: project })
      end

      def project_group_links_serialized(group_links)
        GroupLink::ProjectGroupLinkSerializer
          .new
          .represent(group_links, { current_user: current_user, source: project })
      end

      def group_group_links_serialized(group_links)
        GroupLink::GroupGroupLinkSerializer
          .new
          .represent(group_links, { current_user: current_user, source: project })
      end
      # rubocop:enable CodeReuse/Serializer

      # Mirrors `MembersHelper#members_pagination_data`, which remains in use by
      # the group members helper until that path migrates off helpers too.
      def members_pagination_data(collection, pagination = {})
        {
          current_page: collection.respond_to?(:current_page) ? collection.current_page : nil,
          per_page: collection.respond_to?(:limit_value) ? collection.limit_value : nil,
          total_items: collection.respond_to?(:total_count) ? collection.total_count : collection.count,
          param_name: pagination[:param_name] || nil,
          params: pagination[:params] || {}
        }
      end

      # Overridden in `ee/app/serializers/ee/projects/project_members/app_data_serializer.rb`
      def available_roles
        Gitlab::Access.options_with_owner.map do |name, access_level|
          { title: name, value: "static-#{access_level}" }
        end
      end
    end
  end
end

Projects::ProjectMembers::AppDataSerializer.prepend_mod
