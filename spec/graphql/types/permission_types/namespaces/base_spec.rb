# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Namespaces::Base, feature_category: :groups_and_projects do
  specify do
    expected_permissions = [:admin_label, :read_namespace, :admin_issue, :create_work_item,
      :import_issues, :read_crm_contact, :read_crm_organization]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
