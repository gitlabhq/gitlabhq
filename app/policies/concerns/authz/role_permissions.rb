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

            # These condition names are dynamically generated based on permissions defined in roles.
            # This data is static in config/authz/roles so this is not a security concern
            rule { public_send(:"role_enables_#{permission}") }.enable permission # rubocop:disable GitlabSecurity/PublicSend -- see above
          end
        end
      end
    end

    def role
      Authz::Role.get_from_access_level(team_access_level)
    end
  end
end
