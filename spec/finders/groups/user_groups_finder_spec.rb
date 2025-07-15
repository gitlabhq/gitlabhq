# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UserGroupsFinder, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:root_group) { create(:group, name: 'Root group', path: 'root-group') }
    let_it_be(:guest_group) { create(:group, name: 'public guest', path: 'public-guest') }
    let_it_be(:private_maintainer_group) { create(:group, :private, name: 'b private maintainer', path: 'b-private-maintainer', parent: root_group) }
    let_it_be(:public_developer_group) { create(:group, project_creation_level: nil, name: 'c public developer', path: 'c-public-developer', parent: root_group) }
    let_it_be(:public_maintainer_group) { create(:group, name: 'a public maintainer', path: 'a-public-maintainer', parent: root_group) }
    let_it_be(:public_owner_group) { create(:group, name: 'a public owner', path: 'a-public-owner') }

    subject(:result) { described_class.new(current_user, target_user, arguments.merge(search_arguments)).execute }

    let(:arguments) { {} }
    let(:current_user) { user }
    let(:target_user) { user }
    let(:search_arguments) { {} }

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
      let(:search_arguments) { { exact_matches_first: true, search: private_maintainer_group.path } }
      let(:other_groups) { [] }

      before do
        2.times do
          new_group = create(:group, :private, path: "1-#{SecureRandom.hex}-#{private_maintainer_group.path}", parent: root_group)
          new_group.add_owner(current_user)
          other_groups << new_group
        end
      end

      it 'prioritizes exact matches first', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/537365' do
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
  end
end
