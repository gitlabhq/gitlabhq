# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UserGroupsFinder, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:organization) { user.organization }
    let_it_be(:root_group) { create(:group, name: 'Root group', path: 'root-group') }
    let_it_be(:guest_group) { create(:group, name: 'public guest', path: 'public-guest') }
    let_it_be(:private_maintainer_group) { create(:group, :private, name: 'b private maintainer', path: 'b-private-maintainer', parent: root_group) }
    let_it_be(:public_developer_group) { create(:group, project_creation_level: nil, name: 'c public developer', path: 'c-public-developer', parent: root_group) }
    let_it_be(:public_maintainer_group) { create(:group, name: 'a public maintainer', path: 'a-public-maintainer', parent: root_group) }
    let_it_be(:public_owner_group) { create(:group, name: 'a public owner', path: 'a-public-owner') }
    let(:arguments) { {} }
    let(:current_user) { user }
    let(:target_user) { user }
    let(:search_arguments) { {} }
    let(:organization_arguments) { { organization: organization } }

    subject(:result) do
      described_class.new(current_user, target_user, organization_arguments.merge(arguments, search_arguments)).execute
    end

    before_all do
      guest_group.add_guest(user)
      private_maintainer_group.add_maintainer(user)
      public_developer_group.add_developer(user)
      public_maintainer_group.add_maintainer(user)
      public_owner_group.add_owner(user)
    end

    shared_examples 'user group finder searching by name or path' do
      let(:search_arguments) { { search: 'maintainer' } }

      specify do
        is_expected.to contain_exactly(
          public_maintainer_group,
          private_maintainer_group
        )
      end

      context 'when searching for a full path (including parent)' do
        let(:search_arguments) { { search: 'root-group/b-private-maintainer' } }

        specify do
          is_expected.to contain_exactly(private_maintainer_group)
        end
      end

      context 'when search keywords include the parent route' do
        let(:search_arguments) { { search: 'root public' } }

        specify do
          is_expected.to match(keyword_search_expected_groups)
        end
      end

      context 'when sorting results by similarity' do
        let(:search_arguments) { { search: 'maintainer', sort: :similarity } }

        it 'sorts the results' do
          is_expected.to eq(
            [
              public_maintainer_group,
              private_maintainer_group
            ]
          )
        end
      end
    end

    context 'when sorting results' do
      context 'when sorting by name' do
        context 'in ascending order' do
          let(:arguments) { { sort: :name_asc } }

          it 'sorts the groups by name in ascending order' do
            is_expected.to eq(
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

        context 'in descending order' do
          let(:arguments) { { sort: :name_desc } }

          it 'sorts the groups by name in descending order' do
            is_expected.to eq(
              [
                guest_group,
                public_developer_group,
                private_maintainer_group,
                public_owner_group,
                public_maintainer_group
              ]
            )
          end
        end
      end

      context 'when sorting by path' do
        context 'in ascending order' do
          let(:arguments) { { sort: :path_asc } }

          it 'sorts the groups by path in ascending order' do
            is_expected.to eq(
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

        context 'in descending order' do
          let(:arguments) { { sort: :path_desc } }

          it 'sorts the groups by path in descending order' do
            is_expected.to eq(
              [
                guest_group,
                public_developer_group,
                private_maintainer_group,
                public_owner_group,
                public_maintainer_group
              ]
            )
          end
        end
      end

      context 'when sorting by ID' do
        context 'in ascending order' do
          let(:arguments) { { sort: :id_asc } }

          it 'sorts the groups by ID in ascending order' do
            is_expected.to eq(
              [
                guest_group,
                private_maintainer_group,
                public_developer_group,
                public_maintainer_group,
                public_owner_group
              ]
            )
          end
        end

        context 'in descending order' do
          let(:arguments) { { sort: :id_desc } }

          it 'sorts the groups by ID in descending order' do
            is_expected.to eq(
              [
                public_owner_group,
                public_maintainer_group,
                public_developer_group,
                private_maintainer_group,
                guest_group
              ]
            )
          end
        end
      end
    end

    context 'on searching with exact_matches_first' do
      let(:search_arguments) { { exact_matches_first: true, search: private_maintainer_group.full_path } }
      let(:other_groups) { [] }

      before do
        2.times do
          new_group = create(:group, :private, path: "1-#{SecureRandom.hex}-#{private_maintainer_group.path}", parent: private_maintainer_group)
          new_group.add_owner(current_user)
          other_groups << new_group
        end
      end

      it 'prioritizes exact matches first' do
        expect(result.first).to eq(private_maintainer_group)
        expect(result[1..]).to match_array(other_groups)
      end
    end

    it 'returns all groups where the user is a direct member' do
      is_expected.to contain_exactly(
        public_maintainer_group,
        public_owner_group,
        private_maintainer_group,
        public_developer_group,
        guest_group
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

    context 'when current_user is an owner of the scoped organization' do
      let_it_be(:scoped_organization) { create(:organization) }
      let_it_be(:owner) { create(:user) }
      let_it_be(:scoped_group) { create(:group, organization: scoped_organization) }

      let(:current_user) { owner }
      let(:arguments) { { organization: scoped_organization } }

      before_all do
        create(:organization_user, :owner, organization: scoped_organization, user: owner)
        create(:organization_user, organization: scoped_organization, user: user)
        scoped_group.add_maintainer(user)
      end

      it 'returns the target user groups within the organization' do
        is_expected.to contain_exactly(scoped_group)
      end

      context 'when the target user is not a member of the organization' do
        let_it_be(:other_organization) { create(:organization) }
        let_it_be(:outside_user) { create(:user, organizations: [other_organization]) }
        let_it_be(:outside_group) { create(:group, organization: other_organization, maintainers: outside_user) }

        let(:target_user) { outside_user }

        it { is_expected.to be_empty }
      end

      context 'when current_user is only a member of the organization' do
        let(:current_user) { create(:user) }

        before do
          create(:organization_user, organization: scoped_organization, user: current_user)
        end

        it { is_expected.to be_empty }
      end
    end

    context 'when current_user is an owner of a different organization than the scoped one' do
      let_it_be(:org_a) { create(:organization) }
      let_it_be(:org_b) { create(:organization) }
      let_it_be(:owner_a) { create(:user) }
      let_it_be(:group_in_b) { create(:group, organization: org_b) }

      let(:current_user) { owner_a }
      let(:arguments) { { organization: org_b } }

      before_all do
        create(:organization_user, :owner, organization: org_a, user: owner_a)
        create(:organization_user, organization: org_b, user: user)
        group_in_b.add_maintainer(user)
      end

      it { is_expected.to be_empty }
    end

    context 'when permission is :create_projects' do
      let(:arguments) { { permission_scope: :create_projects } }

      specify do
        is_expected.to contain_exactly(
          public_maintainer_group,
          public_owner_group,
          private_maintainer_group,
          public_developer_group
        )
      end

      it_behaves_like 'user group finder searching by name or path' do
        let(:keyword_search_expected_groups) do
          [
            public_maintainer_group,
            public_developer_group
          ]
        end
      end
    end

    context 'when permission is :import_projects' do
      let(:arguments) { { permission_scope: :import_projects } }

      specify do
        is_expected.to contain_exactly(
          public_maintainer_group,
          public_owner_group,
          private_maintainer_group
        )
      end

      it_behaves_like 'user group finder searching by name or path' do
        let(:keyword_search_expected_groups) do
          [public_maintainer_group]
        end
      end
    end

    context 'when permission is :transfer_projects' do
      let(:arguments) { { permission_scope: :transfer_projects } }

      specify do
        is_expected.to contain_exactly(
          public_maintainer_group,
          public_owner_group,
          private_maintainer_group
        )
      end

      it_behaves_like 'user group finder searching by name or path' do
        let(:keyword_search_expected_groups) { [public_maintainer_group] }
      end
    end

    context 'when scoping by organization' do
      let_it_be(:different_organization) { create(:organization, name: "different org") }
      let_it_be(:different_group) { create(:group, organization: different_organization, name: 'a different public owner') }
      let_it_be(:organization_user) { create(:organization_user, user: user, organization: different_organization) }
      let_it_be(:arguments) { { organization: different_organization } }

      before_all do
        different_group.add_owner(user)
      end

      it 'only returns scoped results' do
        is_expected.to contain_exactly(different_group)
      end
    end

    context 'when solo_owned is true' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:co_owned_group) { create(:group, organization: organization, owners: user) }
      let_it_be(:solo_owned_group) { create(:group, organization: organization, owners: user) }
      let_it_be(:other_organization_group) { create(:group, owners: user) }
      let(:arguments) { { solo_owned: true, organization: organization } }

      before_all do
        co_owned_group.add_owner(create(:user))
      end

      it 'returns only groups solely owned by the user within the organization' do
        is_expected.to contain_exactly(solo_owned_group)
      end

      context 'with a subgroup where the user is the only owner of both parent and subgroup' do
        let_it_be(:parent_group) { create(:group, organization: organization, owners: user) }
        let_it_be(:subgroup) { create(:group, parent: parent_group, organization: organization, owners: user) }

        it 'includes the parent but not the subgroup' do
          is_expected.to include(parent_group)
          is_expected.not_to include(subgroup)
        end
      end

      context 'with an inherited co-owned subgroup (parent has another owner)' do
        let_it_be(:other_owner) { create(:user) }
        let_it_be(:parent_group) { create(:group, organization: organization, owners: [user, other_owner]) }
        let_it_be(:subgroup) { create(:group, parent: parent_group, organization: organization, owners: user) }

        it 'excludes both the co-owned parent and the subgroup (inherited co-ownership disqualifies it)' do
          is_expected.not_to include(parent_group)
          is_expected.not_to include(subgroup)
        end
      end
    end
  end
end
