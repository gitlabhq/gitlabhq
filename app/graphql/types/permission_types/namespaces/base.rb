# frozen_string_literal: true

module Types
  module PermissionTypes
    module Namespaces
      class Base < BasePermissionType
        graphql_name 'NamespacePermissions'

        abilities :admin_label, :admin_issue, :create_work_item,
          :import_issues, :create_projects, :import_work_items, :admin_project

        ability_field :read_namespace

        ability_field :set_new_work_item_metadata,
          description: 'If `true`, the user can set work item metadata for new work items.'

        field :read_crm_contact, GraphQL::Types::Boolean,
          description: 'If `true`, the user can read CRM contacts.',
          null: false

        field :read_crm_organization, GraphQL::Types::Boolean, # rubocop:disable GraphQL/ExtractType -- Custom fields for CRM permissions that check against crm_group
          description: 'If `true`, the user can read CRM organizations.',
          null: false

        def read_crm_contact
          Ability.allowed?(context[:current_user], :read_crm_contact, object.crm_group)
        end

        def read_crm_organization
          Ability.allowed?(context[:current_user], :read_crm_organization, object.crm_group)
        end
      end
    end
  end
end

::Types::PermissionTypes::Namespaces::Base.prepend_mod
