# frozen_string_literal: true

module Types
  module PermissionTypes
    module Namespaces
      class Base < BasePermissionType
        graphql_name 'NamespacePermissions'

        abilities :admin_label, :admin_issue, :create_work_item,
          :import_issues, :read_crm_contact, :read_crm_organization, :create_projects

        ability_field :read_namespace
      end
    end
  end
end

::Types::PermissionTypes::Namespaces::Base.prepend_mod
