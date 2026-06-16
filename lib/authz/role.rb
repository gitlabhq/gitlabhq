# frozen_string_literal: true

module Authz
  class Role
    BASE_PATH = 'config/authz/roles'

    RESOURCE_SCOPES = %i[project group organization].freeze
    VALID_SCOPES = (%i[all] + RESOURCE_SCOPES).freeze

    class << self
      def get(role_name)
        @cache ||= {}
        @cache[role_name.to_sym] ||= new(load_role_data(role_name))
      end

      def get_from_access_level(access_level)
        return unless access_level > Gitlab::Access::NO_ACCESS

        get(Gitlab::Access.human_access(access_level).parameterize.underscore.downcase.to_sym)
      end

      def reset!
        @cache = nil
        @conditionally_enables_requirements = nil
      end

      # Maps each permission that declares `conditionally_enables:` to the set
      # of broader permissions it lists. Used by role expansion: a permission
      # is granted to the role when the role holds *every* permission in its
      # requirement set.
      def conditionally_enables_requirements
        @conditionally_enables_requirements ||= Authz::Permission.all.each_with_object({}) do |(_, permission), index|
          requirements = permission.conditionally_enables
          next if requirements.nil? || requirements.empty?

          index[permission.name.to_sym] = requirements.to_set
        end
      end

      private

      def load_role_data(role_name)
        path = Rails.root.join(BASE_PATH, "#{role_name}.yml")

        raise ArgumentError, "Role definition not found for: #{path}" unless File.exist?(path)

        role_data = YAML.safe_load_file(path).deep_symbolize_keys
        role_data[:inherits_from] = Array(role_data[:inherits_from]).map(&:to_sym)

        RESOURCE_SCOPES.each do |scope|
          role_data[scope] ||= {}
          role_data[scope][:raw_permissions] = Array(role_data[scope][:raw_permissions]).map(&:to_sym)
          role_data[scope][:permissions] = Array(role_data[scope][:permissions]).map(&:to_sym)
        end

        role_data
      end
    end

    def initialize(role_data)
      @role_data = role_data
    end

    # Returns all permissions (project + group + organization) for this role
    # including permissions from inherited roles. This can be limited to a
    # single scope by supplying the optional scope argument
    def permissions(scope)
      raise ArgumentError, "Invalid scope: #{scope}" if VALID_SCOPES.exclude?(scope)

      return project_permissions if scope == :project
      return group_permissions if scope == :group
      return organization_permissions if scope == :organization

      @all_permissions ||= project_permissions | group_permissions | organization_permissions
    end

    # Returns only the permissions directly defined in this role's YAML file
    # for the given scope. Does not include permissions inherited from other roles.
    def direct_permissions(scope)
      raise ArgumentError, "Invalid scope: #{scope}" if VALID_SCOPES.exclude?(scope)

      return direct_project_permissions if scope == :project
      return direct_group_permissions if scope == :group
      return direct_organization_permissions if scope == :organization

      @all_direct_permissions ||= direct_project_permissions | direct_group_permissions |
        direct_organization_permissions
    end

    protected

    def resolve_permissions(scope, evaluated_roles)
      return Set.new if evaluated_roles.include?(@role_data[:name])

      evaluated_roles.add(@role_data[:name])

      inherited = @role_data[:inherits_from].each_with_object(Set.new) do |parent_name, set|
        set.merge(self.class.get(parent_name).resolve_permissions(scope, evaluated_roles))
      end

      expand_conditionally_enables(inherited | direct_permissions(scope))
    end

    private

    def raw_permissions(scope)
      Set.new(@role_data.dig(scope, :raw_permissions))
    end

    def assignable_permissions(scope)
      Set.new(@role_data.dig(scope, :permissions))
    end

    def expand_assignable_permissions(scope)
      assignable_permissions(scope).each_with_object(Set.new) do |name, set|
        set.merge(Authz::PermissionGroups::Assignable.get(name).permissions)
      end
    end

    # Returns all project permissions for this role including permissions
    # from inherited roles and those derived via `conditionally_enables:` expansion.
    def project_permissions
      @project_permissions ||= resolve_permissions(:project, Set.new)
    end

    # Returns all group permissions for this role including permissions
    # from inherited roles and those derived via `conditionally_enables:` expansion.
    def group_permissions
      @group_permissions ||= resolve_permissions(:group, Set.new)
    end

    # Returns all organization permissions for this role including permissions
    # from inherited roles and those derived via `conditionally_enables:` expansion.
    def organization_permissions
      @organization_permissions ||= resolve_permissions(:organization, Set.new)
    end

    # Returns a new set that includes every permission in `set` plus every
    # permission whose `conditionally_enables:` requirements are all satisfied
    # by the expanding set. Repeats until the set stops growing, which handles
    # transitive chains (a newly added permission may itself satisfy another
    # candidate's requirements) and terminates on cycles, since an
    # unsatisfiable requirement set never grows the result.
    def expand_conditionally_enables(set)
      expanded = set.dup

      loop do
        before = expanded.size
        conditionally_enables_requirements.each do |name, requirements|
          expanded.add(name) if requirements.subset?(expanded)
        end
        break if expanded.size == before
      end

      expanded
    end

    def conditionally_enables_requirements
      self.class.conditionally_enables_requirements
    end

    def direct_project_permissions
      @direct_project_permissions ||= raw_permissions(:project) | expand_assignable_permissions(:project)
    end

    def direct_group_permissions
      @direct_group_permissions ||= raw_permissions(:group) | expand_assignable_permissions(:group)
    end

    def direct_organization_permissions
      @direct_organization_permissions ||=
        raw_permissions(:organization) | expand_assignable_permissions(:organization)
    end
  end
end
