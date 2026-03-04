# frozen_string_literal: true

module Authz
  class Role
    BASE_PATH = 'config/authz/roles'

    def initialize(role_data)
      @role_data = role_data
    end

    # Returns all permissions for this role including permissions
    # from inherited roles.
    def permissions
      @permissions ||= resolve_permissions(Set.new)
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
        role_data[:raw_permissions] = Array(role_data[:raw_permissions]).map(&:to_sym)
        role_data[:permissions] = Array(role_data[:permissions]).map(&:to_sym)
        role_data[:inherits_from] = Array(role_data[:inherits_from]).map(&:to_sym)
        role_data
      end
    end

    protected

    def resolve_permissions(evaluated_roles)
      return [] if evaluated_roles.include?(@role_data[:name])

      evaluated_roles.add(@role_data[:name])

      inherited = @role_data[:inherits_from].flat_map do |parent_name|
        self.class.get(parent_name).resolve_permissions(evaluated_roles)
      end

      (inherited + direct_permissions).uniq
    end

    private

    # Returns only the permissions directly defined in this role's YAML file.
    # Does not include permissions inherited from other roles.
    def direct_permissions
      assignable = expand_assignable_permissions

      (raw_permissions + assignable).uniq
    end

    def raw_permissions
      @role_data.fetch(:raw_permissions, [])
    end

    def assignable_permissions
      @role_data.fetch(:permissions, [])
    end

    def expand_assignable_permissions
      assignable_permissions.flat_map do |name|
        Authz::PermissionGroups::Assignable.get(name).permissions
      end
    end
  end
end
