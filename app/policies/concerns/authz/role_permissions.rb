# frozen_string_literal: true

module Authz
  module RolePermissions
    extend ActiveSupport::Concern

    included do
      def self.define_role_permissions(boundary)
        seen_permissions = Set.new

        Gitlab::Access.sym_options_with_owner.each_key do |role_name|
          Authz::Role.get(role_name).permissions(boundary).each do |permission|
            next if seen_permissions.include?(permission)

            seen_permissions.add(permission)

            condition(:"role_enables_#{permission}") do
              next false unless role

              role.permissions(boundary).include?(permission)
            end

            rule { cond(:"role_enables_#{permission}") }.enable permission
          end
        end
      end
    end

    def role
      Authz::Role.get_from_access_level(access_level)
    end

    def access_level
      raise NotImplementedError, "#{self.class} must implement #access_level"
    end
  end
end
