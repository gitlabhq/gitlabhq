# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Namespaces::Base, feature_category: :groups_and_projects do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  specify do
    expected_permissions = [:admin_label, :read_namespace, :admin_issue, :create_work_item,
      :import_issues, :read_crm_contact, :read_crm_organization, :create_projects, :set_new_work_item_metadata,
      :import_work_items, :admin_project]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end

  describe 'CRM permissions' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group_with_crm) { create(:group) }
    let_it_be(:group_without_crm) { create(:group) }
    let_it_be(:project_with_crm) { create(:project, group: group_with_crm) }
    let_it_be(:project_without_crm) { create(:project, group: group_without_crm) }

    before_all do
      create(:crm_settings, group: group_without_crm, enabled: false)
      group_with_crm.add_owner(user)
      group_without_crm.add_owner(user)
    end

    where(:namespace, :expected_value) do
      ref(:group_with_crm)      | true
      ref(:group_without_crm)   | false
      ref(:project_with_crm)    | true
      ref(:project_without_crm) | false
    end

    with_them do
      it 'returns correct CRM permissions' do
        expect(resolve_field(:read_crm_contact, namespace, current_user: user,
          object_type: described_class)).to eq(expected_value)
        expect(resolve_field(:read_crm_organization, namespace, current_user: user,
          object_type: described_class)).to eq(expected_value)
      end
    end
  end
end
