# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Namespaces::Base, feature_category: :groups_and_projects do
  specify do
    expected_permissions = [:admin_label, :read_namespace, :admin_issue, :create_work_item,
      :import_issues, :read_crm_contact, :read_crm_organization, :create_projects, :set_new_work_item_metadata]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
