# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::GroupsResolver do
  include GraphqlHelpers
  include AdminModeHelper

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:guest_group) { create(:group, name: 'public guest', path: 'public-guest') }
    let_it_be(:private_maintainer_group) { create(:group, :private, name: 'b private maintainer', path: 'b-private-maintainer') }
    let_it_be(:public_developer_group) { create(:group, project_creation_level: nil, name: 'c public developer', path: 'c-public-developer') }
    let_it_be(:public_maintainer_group) { create(:group, name: 'a public maintainer', path: 'a-public-maintainer') }
    let_it_be(:public_owner_group) { create(:group, name: 'a public owner', path: 'a-public-owner') }

    subject(:resolved_items) { resolve_groups(args: group_arguments, current_user: current_user, obj: resolver_object) }

    let(:group_arguments) { {} }
    let(:current_user) { user }
    let(:resolver_object) { user }

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

        specify do
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

        specify do
          is_expected.to match(
            [
              public_maintainer_group,
              public_owner_group,
              private_maintainer_group
            ]
          )
        end
      end

      specify do
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

        specify do
          is_expected.to match(
            [
              public_maintainer_group,
              private_maintainer_group
            ]
          )
        end
      end
    end

    context 'when resolver object is different from current user' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_nil }

      context 'when current_user is admin' do
        let(:current_user) { create(:user, :admin) }

        before do
          enable_admin_mode!(current_user)
        end

        specify do
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
    resolve(described_class, args: args, ctx: { current_user: current_user }, obj: obj, arg_style: :internal)&.items
  end
end
