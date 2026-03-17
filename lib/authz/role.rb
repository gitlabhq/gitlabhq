# frozen_string_literal: true

module Authz
  class Role
    BASE_PATH = 'config/authz/roles'

    SCOPES = %i[project group].freeze

    def initialize(role_data)
      @role_data = role_data
    end

    # Returns all project permissions for this role including permissions
    # from inherited roles.
    def project_permissions
      @project_permissions ||= resolve_permissions(:project, Set.new)
    end

    # Returns all group permissions for this role including permissions
    # from inherited roles.
    def group_permissions
      @group_permissions ||= resolve_permissions(:group, Set.new)
    end

    # Returns all permissions (project + group) for this role including
    # permissions from inherited roles.
    def permissions
      @permissions ||= (project_permissions + group_permissions).uniq
    end

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
      end

      private

      def load_role_data(role_name)
        path = Rails.root.join(BASE_PATH, "#{role_name}.yml")

        raise ArgumentError, "Role definition not found for: #{path}" unless File.exist?(path)

        role_data = YAML.safe_load_file(path).deep_symbolize_keys
        role_data[:inherits_from] = Array(role_data[:inherits_from]).map(&:to_sym)

        SCOPES.each do |scope|
          role_data[scope] ||= {}
          role_data[scope][:raw_permissions] = Array(role_data[scope][:raw_permissions]).map(&:to_sym)
          role_data[scope][:permissions] = Array(role_data[scope][:permissions]).map(&:to_sym)
        end

        role_data
      end
    end

    # Returns only the permissions directly defined in this role's YAML file
    # for the given scope. Does not include permissions inherited from other roles.
    def direct_permissions(scope)
      assignable = expand_assignable_permissions(scope)

      (raw_permissions(scope) + assignable).uniq
    end

    protected

    def resolve_permissions(scope, evaluated_roles)
      return [] if evaluated_roles.include?(@role_data[:name])

      evaluated_roles.add(@role_data[:name])

      inherited = @role_data[:inherits_from].flat_map do |parent_name|
        self.class.get(parent_name).resolve_permissions(scope, evaluated_roles)
      end

      (inherited + direct_permissions(scope)).uniq
    end

    private

    def raw_permissions(scope)
      @role_data.dig(scope, :raw_permissions) || []
    end

    def assignable_permissions(scope)
      @role_data.dig(scope, :permissions) || []
    end

    def expand_assignable_permissions(scope)
      assignable_permissions(scope).flat_map do |name|
        Authz::PermissionGroups::Assignable.get(name).permissions
      end
    end
  end
end
