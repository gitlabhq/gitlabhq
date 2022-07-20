# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UserGroupsFinder do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:guest_group) { create(:group, name: 'public guest', path: 'public-guest') }
    let_it_be(:private_maintainer_group) { create(:group, :private, name: 'b private maintainer', path: 'b-private-maintainer') }
    let_it_be(:public_developer_group) { create(:group, project_creation_level: nil, name: 'c public developer', path: 'c-public-developer') }
    let_it_be(:public_maintainer_group) { create(:group, name: 'a public maintainer', path: 'a-public-maintainer') }
    let_it_be(:public_owner_group) { create(:group, name: 'a public owner', path: 'a-public-owner') }

    subject { described_class.new(current_user, target_user, arguments).execute }

    let(:arguments) { {} }
    let(:current_user) { user }
    let(:target_user) { user }

    before_all do
      guest_group.add_guest(user)
      private_maintainer_group.add_maintainer(user)
      public_developer_group.add_developer(user)
      public_maintainer_group.add_maintainer(user)
      public_owner_group.add_owner(user)
    end

    it 'returns all groups where the user is a direct member' do
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

    context 'when target_user is nil' do
      let(:target_user) { nil }

      it { is_expected.to be_empty }
    end

    context 'when current_user is nil' do
      let(:current_user) { nil }

      it { is_expected.to be_empty }
    end

    context 'when permission is :create_projects' do
      let(:arguments) { { permission_scope: :create_projects } }

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

      context 'when search is provided' do
        let(:arguments) { { permission_scope: :create_projects, search: 'maintainer' } }

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

    context 'when permission is :transfer_projects' do
      let(:arguments) { { permission_scope: :transfer_projects } }

      specify do
        is_expected.to match(
          [
            public_maintainer_group,
            public_owner_group,
            private_maintainer_group
          ]
        )
      end

      context 'when search is provided' do
        let(:arguments) { { permission_scope: :transfer_projects, search: 'owner' } }

        specify do
          is_expected.to match(
            [
              public_owner_group
            ]
          )
        end
      end
    end

    context 'when search is provided' do
      let(:arguments) { { search: 'maintainer' } }

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
end
