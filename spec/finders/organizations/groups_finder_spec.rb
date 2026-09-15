# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsFinder, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:organization_user) { create(:organization_user) }
    let_it_be(:organization) { organization_user.organization }
    let_it_be(:user) { organization_user.user }
    let_it_be(:other_organization) { create(:organization) }
    let_it_be_with_reload(:public_group) { create(:group, name: 'public-group', organization: organization) }
    let_it_be_with_reload(:outside_organization_group) do
      create(:group, name: 'outside-organization', organization: other_organization)
    end

    let_it_be_with_reload(:private_group) do
      create(:group, :private, name: 'private-group', organization: organization)
    end

    let_it_be_with_reload(:no_access_group_in_org) do
      create(:group, :private, name: 'no-access', organization: organization)
    end

    let(:current_user) { user }
    let(:params) { { organization: organization } }
    let(:finder) { described_class.new(current_user, params) }

    subject(:result) { finder.execute.to_a }

    before_all do
      private_group.add_developer(user)
      public_group.add_developer(user)
      outside_organization_group.add_developer(user)
    end

    context 'when user is only authorized to read the public group' do
      let(:current_user) { create(:user) }

      it { is_expected.to contain_exactly(public_group) }
    end

    it 'return all groups inside the organization' do
      expect(result).to contain_exactly(public_group, private_group)
    end

    it 'creates a CTE with filtered groups' do
      allow(Gitlab::SQL::CTE).to receive(:new).and_call_original
      expect(Gitlab::SQL::CTE).to receive(:new).with(
        :filtered_groups_cte, kind_of(ActiveRecord::Relation), materialized: false
      )

      result
    end

    context 'with default organization' do
      # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- the finder branches on
      # `organization.default?`, so this path can only be covered with the default organization.
      let_it_be(:default_organization) { create(:organization, :default) }
      # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization
      let_it_be(:default_organization_public_group) do
        create(:group, name: 'default-public-group', organization: default_organization, developers: user)
      end

      let_it_be(:default_organization_private_group) do
        create(:group, :private, name: 'default-private-group', organization: default_organization, developers: user)
      end

      let_it_be(:default_organization_no_access_group) do
        create(:group, :private, name: 'default-no-access', organization: default_organization)
      end

      let(:params) { { organization: default_organization } }

      it { is_expected.to contain_exactly(default_organization_public_group, default_organization_private_group) }

      it 'does not build a query using the CTE' do
        allow(Gitlab::SQL::CTE).to receive(:new).and_call_original
        expect(Gitlab::SQL::CTE).not_to receive(:new).with(
          :filtered_groups_cte, kind_of(ActiveRecord::Relation), materialized: false
        )

        result
      end
    end

    it 'filters deleted groups' do
      public_group.update!(state: :deletion_in_progress)

      expect(result).not_to include(public_group)
    end

    context 'with owned: true' do
      let_it_be(:owned_group) { create(:group, organization: organization, owners: user) }
      let_it_be(:other_org_owned_group) { create(:group, organization: other_organization, owners: user) }
      let_it_be(:developer_group) { create(:group, organization: organization) }

      let(:params) { { organization: organization, owned: true } }

      before_all do
        developer_group.add_developer(user)
      end

      it 'returns only groups where the user is an owner' do
        expect(result).to contain_exactly(owned_group)
      end

      context 'when user is anonymous' do
        let(:current_user) { nil }

        it 'returns no groups, not even public ones' do
          expect(result).to be_empty
        end
      end

      context 'with default organization' do
        # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- the finder branches on
        # `organization.default?`, so this path can only be covered with the default organization.
        let_it_be(:default_organization) { create(:organization, :default) }
        # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization
        let_it_be(:default_organization_owned_group) do
          create(:group, organization: default_organization, owners: user)
        end

        let_it_be(:default_organization_developer_group) do
          create(:group, organization: default_organization, developers: user)
        end

        let(:params) { { organization: default_organization, owned: true } }

        it 'returns only groups where the user is an owner' do
          expect(result).to contain_exactly(default_organization_owned_group)
        end
      end
    end
  end
end
