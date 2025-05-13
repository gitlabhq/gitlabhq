# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Group, feature_category: :groups_and_projects do
  include GraphqlHelpers

  it 'has the correct permissions' do
    expected_permissions = [
      :read_group, :create_projects, :create_custom_emoji, :remove_group, :view_edit_page, :can_leave,
      :admin_issue, :read_crm_contact, :read_crm_organization
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end

  describe '#can_leave' do
    let_it_be(:group) { create(:group) }

    subject { resolve_field(:can_leave, group, current_user: user) }

    context 'when authenticated' do
      let_it_be(:user) { create(:user) }

      context 'when user is member' do
        context 'when user has permission to leave the group' do
          let_it_be(:group_owner) { create(:group_member, :owner, group: group, user: create(:user)) }
          let_it_be(:group_member) { create(:group_member, group: group, user: user) }

          it { is_expected.to be(true) }
        end

        context 'when user has no permission to leave the group' do
          let_it_be(:group_owner) { create(:group_member, :owner, user: user) }

          it { is_expected.to be(false) }
        end
      end

      context 'when user is not a member' do
        it { is_expected.to be(false) }
      end
    end

    context 'when unauthenticated' do
      let_it_be(:user) { nil }

      it { is_expected.to be(false) }
    end
  end
end
