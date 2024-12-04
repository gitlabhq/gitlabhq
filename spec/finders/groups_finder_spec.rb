# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsFinder, feature_category: :groups_and_projects do
  include AdminModeHelper
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let(:user) { create(:user) }

    describe 'root level groups' do
      where(:user_type, :params, :results) do
        nil | { all_available: true } | %i[public_group user_public_group]
        nil | { all_available: false } | %i[public_group user_public_group]
        nil | {} | %i[public_group user_public_group]

        :regular | { all_available: true } | %i[public_group internal_group user_public_group user_internal_group
                                                user_private_group]
        :regular | { all_available: false } | %i[user_public_group user_internal_group user_private_group]
        :regular | {} | %i[public_group internal_group user_public_group user_internal_group user_private_group]
        :regular | { min_access_level: Gitlab::Access::DEVELOPER } | %i[user_public_group user_internal_group user_private_group]

        :external | { all_available: true } | %i[public_group user_public_group user_internal_group user_private_group]
        :external | { all_available: false } | %i[user_public_group user_internal_group user_private_group]
        :external | {} | %i[public_group user_public_group user_internal_group user_private_group]

        :admin_without_admin_mode | { all_available: true } | %i[public_group internal_group user_public_group
                                                                 user_internal_group user_private_group]
        :admin_without_admin_mode | { all_available: false } | %i[user_public_group user_internal_group user_private_group]
        :admin_without_admin_mode | {} | %i[public_group internal_group user_public_group user_internal_group user_private_group]

        :admin_with_admin_mode | { all_available: true } | %i[public_group internal_group private_group user_public_group
                                                              user_internal_group user_private_group]
        :admin_with_admin_mode | { all_available: false } | %i[user_public_group user_internal_group user_private_group]
        :admin_with_admin_mode | {} | %i[public_group internal_group private_group user_public_group user_internal_group
                                         user_private_group]
      end

      with_them do
        before do
          # Fixme: Because of an issue: https://github.com/tomykaira/rspec-parameterized/issues/8#issuecomment-381888428
          # The groups need to be created here, not with let syntax, and also compared by name and not ids

          @groups = {
            private_group: create(:group, :private, name: 'private_group'),
            internal_group: create(:group, :internal, name: 'internal_group'),
            public_group: create(:group, :public, name: 'public_group'),

            user_private_group: create(:group, :private, name: 'user_private_group'),
            user_internal_group: create(:group, :internal, name: 'user_internal_group'),
            user_public_group: create(:group, :public, name: 'user_public_group')
          }

          if user_type
            user =
              case user_type
              when :regular
                create(:user)
              when :external
                create(:user, external: true)
              when :admin_without_admin_mode
                create(:user, :admin)
              when :admin_with_admin_mode
                admin = create(:user, :admin)
                enable_admin_mode!(admin)
                admin
              end
            @groups.values_at(:user_private_group, :user_internal_group, :user_public_group).each do |group|
              group.add_developer(user)
            end
          end
        end

        subject { described_class.new(User.last, params).execute.to_a }

        it { is_expected.to match_array(@groups.values_at(*results)) }
      end
    end

    context 'subgroups' do
      let(:user) { create(:user) }
      let!(:parent_group) { create(:group, :public) }
      let!(:public_subgroup) { create(:group, :public, parent: parent_group) }
      let!(:internal_subgroup) { create(:group, :internal, parent: parent_group) }
      let!(:private_subgroup) { create(:group, :private, parent: parent_group) }

      context 'with [nil] parent' do
        it 'returns only top-level groups' do
          expect(described_class.new(user, parent: [nil]).execute).to contain_exactly(parent_group)
        end
      end

      context 'without a user' do
        it 'only returns parent and public subgroups' do
          expect(described_class.new(nil).execute).to contain_exactly(parent_group, public_subgroup)
        end
      end

      context 'with a user' do
        subject { described_class.new(user).execute }

        it 'returns parent, public, and internal subgroups' do
          is_expected.to contain_exactly(parent_group, public_subgroup, internal_subgroup)
        end

        context 'being member' do
          it 'returns parent, public subgroups, internal subgroups, and private subgroups user is member of' do
            private_subgroup.add_guest(user)

            is_expected.to contain_exactly(parent_group, public_subgroup, internal_subgroup, private_subgroup)
          end
        end

        context 'parent group private' do
          before do
            parent_group.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          end

          context 'being member of parent group' do
            it 'returns all subgroups' do
              parent_group.add_guest(user)

              is_expected.to contain_exactly(parent_group, public_subgroup, internal_subgroup, private_subgroup)
            end
          end

          context 'authorized to private project' do
            context 'project one level deep' do
              let!(:subproject) { create(:project, :private, namespace: private_subgroup) }

              before do
                subproject.add_guest(user)
              end

              it 'includes the subgroup of the project' do
                is_expected.to include(private_subgroup)
              end

              it 'does not include private subgroups deeper down' do
                subsubgroup = create(:group, :private, parent: private_subgroup)

                is_expected.not_to include(subsubgroup)
              end
            end

            context 'project two levels deep' do
              let!(:private_subsubgroup) { create(:group, :private, parent: private_subgroup) }
              let!(:subsubproject) { create(:project, :private, namespace: private_subsubgroup) }

              before do
                subsubproject.add_guest(user)
              end

              it 'returns all the ancestor groups' do
                is_expected.to include(private_subsubgroup, private_subgroup, parent_group)
              end

              it 'returns the groups for a given parent' do
                expect(described_class.new(user, parent: parent_group).execute).to include(private_subgroup)
              end
            end
          end

          context 'being minimal access member of parent group' do
            it 'do not return group with minimal_access access' do
              create(:group_member, :minimal_access, user: user, source: parent_group)

              is_expected.to contain_exactly(public_subgroup, internal_subgroup)
            end
          end
        end
      end
    end

    context 'with include parent group descendants' do
      let_it_be(:user) { create(:user) }
      let_it_be(:parent_group) { create(:group, :public) }
      let_it_be(:public_subgroup) { create(:group, :public, parent: parent_group) }
      let_it_be(:internal_sub_subgroup) { create(:group, :internal, parent: public_subgroup) }
      let_it_be(:private_sub_subgroup) { create(:group, :private, parent: public_subgroup) }
      let_it_be(:public_sub_subgroup) { create(:group, :public, parent: public_subgroup) }
      let_it_be(:invited_to_group) { create(:group, :public) }
      let_it_be(:invited_to_subgroup) { create(:group, :public) }

      let(:params) { { include_parent_descendants: true, parent: parent_group } }

      before do
        parent_group.shared_with_groups << invited_to_group
        public_subgroup.shared_with_groups << invited_to_subgroup
      end

      context 'with nil parent' do
        before do
          params[:parent] = nil
        end

        it 'returns all accessible groups' do
          expect(described_class.new(user, params).execute).to contain_exactly(
            parent_group,
            public_subgroup,
            internal_sub_subgroup,
            public_sub_subgroup,
            invited_to_group,
            invited_to_subgroup
          )
        end
      end

      context 'without a user' do
        it 'only returns the group public descendants' do
          expect(described_class.new(nil, params).execute).to contain_exactly(
            public_subgroup,
            public_sub_subgroup
          )
        end
      end

      context 'when a user is present' do
        it 'returns the group public and internal descendants' do
          expect(described_class.new(user, params).execute).to contain_exactly(
            public_subgroup,
            public_sub_subgroup,
            internal_sub_subgroup
          )
        end
      end

      context 'when a parent group member is present' do
        before do
          parent_group.add_developer(user)
        end

        it 'returns all group descendants' do
          expect(described_class.new(user, params).execute).to contain_exactly(
            public_subgroup,
            public_sub_subgroup,
            internal_sub_subgroup,
            private_sub_subgroup
          )
        end

        context 'when include shared groups is set' do
          before do
            params[:include_parent_shared_groups] = true
          end

          it 'returns all group descendants with shared groups' do
            expect(described_class.new(user, params).execute).to contain_exactly(
              public_subgroup,
              public_sub_subgroup,
              internal_sub_subgroup,
              private_sub_subgroup,
              invited_to_group
            )
          end
        end
      end
    end

    context 'with search' do
      let_it_be(:parent_group) { create(:group, :public, name: 'Parent Group') }
      let_it_be(:test_group) { create(:group, :public, path: 'test-path') }

      it 'returns all groups with matching title' do
        expect(described_class.new(user, { search: 'parent' }).execute).to contain_exactly(parent_group)
      end

      it 'returns all groups with matching path' do
        expect(described_class.new(user, { search: 'test' }).execute).to contain_exactly(test_group)
      end

      it 'does not search in full path if parent is set' do
        matching_subgroup = create(:group, parent: parent_group, path: "#{parent_group.path}-subgroup")

        expect(described_class.new(user, { search: 'parent', parent: parent_group }).execute).to contain_exactly(matching_subgroup)
      end

      context 'with group descendants' do
        let_it_be(:sub_group) { create(:group, :public, name: 'Sub Group', parent: parent_group) }

        let(:params) { { search: parent_group.path } }

        it 'searches in full path if descendant groups are not included' do
          params[:include_parent_descendants] = false

          expect(described_class.new(user, params).execute).to contain_exactly(parent_group, sub_group)
        end
      end
    end

    context 'with filter_group_ids' do
      let_it_be(:group_one) { create(:group, :public, name: 'group_one') }
      let_it_be(:group_two) { create(:group, :public, name: 'group_two') }
      let_it_be(:group_three) { create(:group, :public, name: 'group_three') }

      subject { described_class.new(user, { filter_group_ids: [group_one.id, group_three.id] }).execute }

      it 'returns only the groups listed in the filter' do
        is_expected.to contain_exactly(group_one, group_three)
      end
    end

    context 'with group ids' do
      let_it_be(:group_one) { create(:group, :public, name: 'group_one') }
      let_it_be(:group_two) { create(:group, :public, name: 'group_two') }
      let_it_be(:group_three) { create(:group, :public, name: 'group_three') }

      subject { described_class.new(user, { ids: [group_one.id, group_three.id] }).execute }

      it 'returns only the groups listed in the list of ids' do
        is_expected.to contain_exactly(group_one, group_three)
      end
    end

    context 'with top level groups only' do
      let_it_be(:group_one) { create(:group, :public, name: 'group_one') }
      let_it_be(:group_two) { create(:group, :public, name: 'group_two', parent: group_one) }
      let_it_be(:group_three) { create(:group, :public, name: 'group_three', parent: group_one) }

      subject { described_class.new(user, { top_level_only: true }).execute }

      it 'returns only top level groups' do
        is_expected.to contain_exactly(group_one)
      end
    end

    context 'with organization' do
      let_it_be(:organization_user) { create(:organization_user) }
      let_it_be(:organization) { organization_user.organization }
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:user) { organization_user.user }
      let_it_be(:public_group) { create(:group, name: 'public-group', organization: organization) }
      let_it_be(:outside_organization_group) { create(:group, organization: other_organization) }
      let_it_be(:private_group) { create(:group, :private, name: 'private-group', organization: organization) }
      let_it_be(:no_access_group_in_org) { create(:group, :private, name: 'no-access', organization: organization) }

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
    end

    context 'with include_ancestors' do
      let_it_be(:user) { create(:user) }

      let_it_be(:parent_group) { create(:group, :public) }
      let_it_be(:public_subgroup) { create(:group, :public, parent: parent_group) }
      let_it_be(:public_subgroup2) { create(:group, :public, parent: parent_group) }
      let_it_be(:private_subgroup1) { create(:group, :private, parent: parent_group) }
      let_it_be(:internal_sub_subgroup) { create(:group, :internal, parent: public_subgroup) }
      let_it_be(:public_sub_subgroup) { create(:group, :public, parent: public_subgroup) }
      let_it_be(:private_subgroup2) { create(:group, :private, parent: parent_group) }
      let_it_be(:private_sub_subgroup) { create(:group, :private, parent: private_subgroup2) }
      let_it_be(:private_sub_sub_subgroup) { create(:group, :private, parent: private_sub_subgroup) }

      context 'if include_ancestors is true' do
        let(:params) { { include_ancestors: true } }

        it 'returns ancestors of user groups' do
          private_sub_subgroup.add_developer(user)

          expect(described_class.new(user, params).execute).to contain_exactly(
            parent_group,
            public_subgroup,
            public_subgroup2,
            internal_sub_subgroup,
            public_sub_subgroup,
            private_subgroup2,
            private_sub_subgroup,
            private_sub_sub_subgroup
          )
        end

        it 'returns subgroup if user is member of project of subgroup' do
          project = create(:project, :private, namespace: private_sub_subgroup)
          project.add_developer(user)

          expect(described_class.new(user, params).execute).to contain_exactly(
            parent_group,
            public_subgroup,
            public_subgroup2,
            internal_sub_subgroup,
            public_sub_subgroup,
            private_subgroup2,
            private_sub_subgroup
          )
        end

        it 'returns only groups related to user groups if all_available is false' do
          params[:all_available] = false
          private_sub_subgroup.add_developer(user)

          expect(described_class.new(user, params).execute).to contain_exactly(
            parent_group,
            private_subgroup2,
            private_sub_subgroup,
            private_sub_sub_subgroup
          )
        end
      end

      context 'if include_ancestors is false' do
        let(:params) { { include_ancestors: false } }

        it 'does not return private ancestors of user groups' do
          private_sub_subgroup.add_developer(user)

          expect(described_class.new(user, params).execute).to contain_exactly(
            parent_group,
            public_subgroup,
            public_subgroup2,
            internal_sub_subgroup,
            public_sub_subgroup,
            private_sub_subgroup,
            private_sub_sub_subgroup
          )
        end

        it "returns project's ancestor groups if user is member of project" do
          project = create(:project, :private, namespace: private_sub_subgroup)
          project.add_developer(user)

          expect(described_class.new(user, params).execute).to contain_exactly(
            parent_group,
            public_subgroup,
            public_subgroup2,
            internal_sub_subgroup,
            public_sub_subgroup,
            private_sub_subgroup,
            private_subgroup2
          )
        end

        it 'returns only user groups and their descendants if all_available is false' do
          params[:all_available] = false
          private_sub_subgroup.add_developer(user)

          expect(described_class.new(user, params).execute).to contain_exactly(
            private_sub_subgroup,
            private_sub_sub_subgroup
          )
        end
      end
    end

    describe 'group sorting' do
      let_it_be(:all_groups) { create_list(:group, 3, :public) }

      subject(:result) { described_class.new(nil, params).execute.to_a }

      where(:field, :direction, :sorted_groups) do
        'id'   | 'asc'  | lazy { all_groups.sort_by(&:id) }
        'id'   | 'desc' | lazy { all_groups.sort_by(&:id).reverse }
        'name' | 'asc'  | lazy { all_groups.sort_by(&:name) }
        'name' | 'desc' | lazy { all_groups.sort_by(&:name).reverse }
        'path' | 'asc'  | lazy { all_groups.sort_by(&:path) }
        'path' | 'desc' | lazy { all_groups.sort_by(&:path).reverse }
      end

      with_them do
        let(:sort) { "#{field}_#{direction}" }
        let(:params) { { sort: sort } }

        it { is_expected.to eq(sorted_groups) }
      end
    end
  end
end
