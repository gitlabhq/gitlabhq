# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::GroupsResolver, feature_category: :groups_and_projects do
  include GraphqlHelpers
  include AdminModeHelper

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:organization) { user.organization }
    let_it_be(:guest_group) { create(:group, name: 'public guest', path: 'public-guest') }
    let_it_be(:private_maintainer_group) { create(:group, :private, name: 'b private maintainer', path: 'b-private-maintainer') }
    let_it_be(:public_developer_group) { create(:group, project_creation_level: nil, name: 'c public developer', path: 'c-public-developer') }
    let_it_be(:public_maintainer_group) { create(:group, name: 'a public maintainer', path: 'a-public-maintainer') }
    let_it_be(:public_owner_group) { create(:group, name: 'a public owner', path: 'a-public-owner') }

    let(:group_arguments) { {} }
    let(:current_user) { user }
    let(:resolver_object) { user }

    subject(:resolved_items) { resolve_groups(args: group_arguments, current_user: current_user, obj: resolver_object) }

    before_all do
      guest_group.add_guest(user)
      private_maintainer_group.add_maintainer(user)
      public_developer_group.add_developer(user)
      public_maintainer_group.add_maintainer(user)
      public_owner_group.add_owner(user)
    end

    context 'when resolver object is current user' do
      context 'when permission is :create_projects' do
        let(:group_arguments) { { permission_scope: :create_projects } }

        it 'returns expected groups' do
          is_expected.to match(
            [
              public_maintainer_group,
              public_owner_group,
              private_maintainer_group,
              public_developer_group
            ]
          )
        end
      end

      context 'when permission is :transfer_projects' do
        let(:group_arguments) { { permission_scope: :transfer_projects } }

        it 'returns expected groups' do
          is_expected.to match(
            [
              public_maintainer_group,
              public_owner_group,
              private_maintainer_group
            ]
          )
        end
      end

      it 'returns expected additional groups' do
        is_expected.to match(
          [
            public_maintainer_group,
            public_owner_group,
            private_maintainer_group,
            public_developer_group,
            guest_group
          ]
        )
      end

      context 'when search is provided' do
        let(:group_arguments) { { search: 'maintainer' } }

        it 'returns expected groups' do
          is_expected.to match(
            [
              public_maintainer_group,
              private_maintainer_group
            ]
          )
        end
      end

      context 'when sort is provided' do
        let(:group_arguments) { { search: 'maintainer', sort: :similarity } }

        it 'returns expected groups in consistent order' do
          is_expected.to eq(
            [
              public_maintainer_group,
              private_maintainer_group
            ]
          )
        end
      end

      context 'when solo_owned is true' do
        let_it_be(:scoped_organization) { create(:organization) }
        let_it_be(:solo_owned_group) { create(:group, organization: scoped_organization, owners: user) }
        let_it_be(:co_owned_group) do
          create(:group, organization: scoped_organization, owners: [user, create(:user)])
        end

        let_it_be(:other_organization_group) { create(:group, owners: user) }

        let(:group_arguments) { { solo_owned: true } }

        subject(:resolved_items) do
          resolve(
            described_class,
            args: group_arguments,
            ctx: { current_user: current_user, current_organization: scoped_organization },
            obj: resolver_object,
            arg_style: :internal
          )&.items
        end

        it 'returns only groups solely owned by the user within the current organization' do
          is_expected.to contain_exactly(solo_owned_group)
        end
      end
    end

    context 'when resolver object is different from current user' do
      let(:current_user) { create(:user) }

      it 'returns nil' do
        expect(resolve_groups_result).to be_nil
      end

      context 'when current_user is anonymous' do
        let(:current_user) { nil }

        it 'returns nil' do
          expect(resolve_groups_result).to be_nil
        end
      end

      context 'when current_user is an owner of the current organization' do
        # Refind so the memoized `owner_user_ids` used by the policy is not shared between examples.
        let_it_be_with_refind(:organization) { user.organization }
        let(:current_user) { create(:user, owner_of: organization) }

        it 'returns expected groups' do
          is_expected.to match(
            [
              public_maintainer_group,
              public_owner_group,
              private_maintainer_group,
              public_developer_group,
              guest_group
            ]
          )
        end
      end

      context 'when current_user is admin' do
        let(:current_user) { create(:user, :admin) }

        before do
          enable_admin_mode!(current_user)
        end

        it 'returns expected groups' do
          is_expected.to match(
            [
              public_maintainer_group,
              public_owner_group,
              private_maintainer_group,
              public_developer_group,
              guest_group
            ]
          )
        end
      end
    end
  end

  def resolve_groups(args:, current_user:, obj:)
    resolve(described_class, args: args, ctx: { current_user: current_user, current_organization: organization }, obj: obj, arg_style: :internal)&.items
  end

  def resolve_groups_result
    resolve(described_class, args: group_arguments, ctx: { current_user: current_user, current_organization: organization }, obj: resolver_object, arg_style: :internal)
  end
end
