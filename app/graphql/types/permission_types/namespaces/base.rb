# frozen_string_literal: true

module Types
  module PermissionTypes
    module Namespaces
      class Base < BasePermissionType
        graphql_name 'NamespacePermissions'

        abilities :admin_label, :admin_issue, :create_work_item,
          :import_issues, :read_crm_contact, :read_crm_organization, :create_projects,
          :import_work_items, :admin_project

        ability_field :read_namespace

        ability_field :set_new_work_item_metadata,
          description: 'If `true`, the user can set work item metadata for new work items.'
      end
    end
  end
end

::Types::PermissionTypes::Namespaces::Base.prepend_mod
