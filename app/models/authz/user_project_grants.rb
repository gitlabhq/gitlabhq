# frozen_string_literal: true

module Authz
  # Resolves every role a user holds on a set of projects from memberships, instead of the single
  # maximum stored in project_authorizations. Covers direct project memberships, memberships of the
  # project's group and its ancestors, and personal projects.
  class UserProjectGrants
    include Gitlab::Utils::StrongMemoize

    # Grants below Guest (Minimal Access) carry a custom role but give no project access.
    Grant = Data.define(:access_level, :member_role_id, :source) do
      def grants_access?
        access_level >= Gitlab::Access::GUEST
      end
    end

    MEMBERSHIPS_CACHE = :authz_user_project_grants_memberships

    # Forgets the user's memberships cached for the request, after they change.
    #
    # @param user_id [Integer]
    # @return [void]
    def self.forget_memberships(user_id)
      Gitlab::SafeRequestStore.delete([MEMBERSHIPS_CACHE, user_id])

      nil
    end

    # @param user_id [Integer, nil] nil for a user that is not persisted, who has no grants
    def initialize(user_id)
      @user_id = user_id
    end

    # Returns every grant the user holds on each given project.
    #
    # @param projects [Array<Project, Integer>, ActiveRecord::Relation] projects, or their IDs
    # @return [Hash{Integer => Array<Grant>}] keyed by project ID, for every project that exists
    def for_projects(projects)
      return {} unless user_id

      rows = sources.project_rows(projects)
      load_relevant_memberships(rows)

      rows.to_h { |project_id, project| [project_id, project_grants(project_id, project)] }
    end

    # Returns the same shape as the project_authorizations lookup.
    #
    # @param projects [Array<Project, Integer>, ActiveRecord::Relation] projects, or their IDs
    # @return [Hash{Integer => Integer}] the highest access level per project, NO_ACCESS when there is none
    def max_access_levels(projects)
      for_projects(projects).transform_values do |grants|
        grants.select(&:grants_access?).map(&:access_level).max || Gitlab::Access::NO_ACCESS
      end
    end

    private

    attr_reader :user_id

    def project_grants(project_id, project)
      grants = []
      grants << Grant.new(Gitlab::Access::OWNER, nil, :personal) if personal_project_owner?(project)

      membership = memberships[:project][project_id]
      grants << Grant.new(membership[:access_level], membership[:member_role_id], :project) if membership

      grants.concat(group_grants(project[:traversal_ids])) if project[:namespace_type] == ::Group.sti_name
      grants
    end

    # Grants on a group from direct memberships in it or its ancestors.
    def group_grants(traversal_ids)
      traversal_ids.filter_map do |group_id|
        direct = memberships[:group][group_id]
        Grant.new(direct[:access_level], direct[:member_role_id], :group) if direct
      end
    end

    def personal_project_owner?(project)
      project[:namespace_type] == ::Namespaces::UserNamespace.sti_name && project[:owner_id] == user_id
    end

    # Loads only the user's memberships that can grant access to these projects: the projects themselves
    # and the groups in each project's hierarchy. This keeps the cost independent of how many memberships
    # the user has elsewhere.
    def load_relevant_memberships(rows)
      load_memberships(
        ::GroupMember::SOURCE_TYPE => sources.hierarchy_group_ids(rows, {}),
        ::ProjectMember::SOURCE_TYPE => rows.keys
      )
    end

    def sources
      ProjectGrantSources.new
    end
    strong_memoize_attr :sources

    # Cached per user for the request, with every source looked up recorded so absences are not queried again.
    def memberships
      Gitlab::SafeRequestStore.fetch([MEMBERSHIPS_CACHE, user_id]) do
        { group: {}, project: {}, loaded: Set.new }
      end
    end
    strong_memoize_attr :memberships

    def load_memberships(source_ids_by_type)
      wanted = source_ids_by_type.flat_map { |type, ids| ids.map { |id| [type, id] } }
        .reject { |key| memberships[:loaded].include?(key) }
      return if wanted.empty?

      queried_memberships(wanted).each do |source_type, source_id, access_level, member_role_id|
        target = source_type == ::ProjectMember::SOURCE_TYPE ? :project : :group
        memberships[target][source_id] = { access_level: access_level, member_role_id: member_role_id }
      end
      memberships[:loaded].merge(wanted)
    end

    # Joining unnested arrays probes the (user_id, source_id, source_type) index once per source,
    # and keeps planning flat however many sources are wanted.
    def queried_memberships(wanted)
      types, ids = wanted.transpose
      wanted_join = ::Member.sanitize_sql_array([
        'INNER JOIN unnest(?::bigint[], ?::text[]) AS wanted(source_id, source_type) ' \
          'ON wanted.source_id = members.source_id AND wanted.source_type = members.source_type',
        pg_array(ids.map { |id| Integer(id) }), pg_array(types)
      ])

      ::Member.where(user_id: user_id).non_request.active_state.joins(wanted_join)
        .pluck(:source_type, :source_id, :access_level, :member_role_id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by the sources being checked
    end

    def pg_array(values)
      "{#{values.join(',')}}"
    end
  end
end
