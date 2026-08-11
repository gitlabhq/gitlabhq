# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupsResolver, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:public_group) { create(:group, name: 'public-group') }
    let_it_be_with_reload(:private_group) { create(:group, :private, name: 'private-group') }

    let(:params) { {} }

    subject { resolve(described_class, args: params, lookahead: positive_lookahead, ctx: { current_user: user }) }

    it 'includes public groups' do
      expect(subject).to contain_exactly(public_group)
    end

    it 'includes accessible private groups' do
      private_group.add_developer(user)
      expect(subject).to contain_exactly(public_group, private_group)
    end

    describe 'ordering' do
      let_it_be(:other_group) { create(:group, name: 'other-group') }

      it 'orders by name ascending' do
        expect(subject.map(&:name)).to eq(%w[other-group public-group])
      end
    end

    context 'with `search` argument' do
      let_it_be(:other_group) { create(:group, name: 'other-group') }

      let(:params) { { search: 'oth' } }

      it 'filters groups by name' do
        expect(subject).to contain_exactly(other_group)
      end
    end

    context 'with `ids` argument' do
      let_it_be(:other_group) { create(:group, name: 'other-group') }

      let(:params) { { ids: [other_group.to_global_id.to_s] } }

      it 'filters groups by gid' do
        expect(subject).to contain_exactly(other_group)
      end
    end

    context 'with `top_level_only` argument' do
      let_it_be(:top_level_group) { create(:group, name: 'top-level-group') }
      let_it_be(:sub_group) { create(:group, name: 'sub_group', parent: top_level_group) }

      context 'with `top_level_only` argument provided' do
        let(:params) { { top_level_only: true } }

        it 'return only top level groups' do
          expect(subject).to contain_exactly(public_group, top_level_group)
        end
      end
    end

    context 'with `owned_only` argument' do
      let_it_be(:owned_group) { create(:group, name: 'with owner role', owners: user) }

      context 'with `owned_only` argument provided' do
        let(:params) { { owned_only: true } }

        it 'return only owned groups' do
          expect(subject).to contain_exactly(owned_group)
        end
      end
    end

    context 'with `parent_path` argument' do
      let_it_be(:parent_group) { private_group }
      let_it_be(:child_group) { create(:group, :private, parent: parent_group) }

      let(:params) { { parent_path: parent_group.full_path } }

      context 'when user has access to parent group' do
        it 'returns child group' do
          parent_group.add_developer(user)

          is_expected.to contain_exactly(child_group)
        end
      end

      context 'when user has no access to parent group' do
        it 'generates error' do
          expect_graphql_error_to_be_created(
            ::Gitlab::Graphql::Errors::ResourceNotAvailable,
            format(_('Could not find parent group with path %{path}'), path: parent_group.full_path)
          ) { subject }
        end
      end

      context 'when parent_path has no match' do
        let(:params) { { parent_path: 'non-existent-group' } }

        it 'generates error' do
          expect_graphql_error_to_be_created(
            ::Gitlab::Graphql::Errors::ResourceNotAvailable,
            format(_('Could not find parent group with path %{path}'), path: 'non-existent-group')
          ) { subject }
        end
      end
    end

    context 'with `include_subgroups` argument' do
      let_it_be(:parent_group) { create(:group, name: 'parent-group') }
      let_it_be(:child_group) { create(:group, name: 'child-group', parent: parent_group) }
      let_it_be(:grandchild_group) { create(:group, name: 'grandchild-group', parent: child_group) }

      context 'when combined with `parent_path`' do
        let(:params) { { parent_path: parent_group.full_path, include_subgroups: true } }

        it 'returns all descendant groups' do
          expect(subject).to contain_exactly(child_group, grandchild_group)
        end

        context 'when `include_subgroups` is false' do
          let(:params) { { parent_path: parent_group.full_path, include_subgroups: false } }

          it 'returns only direct children' do
            expect(subject).to contain_exactly(child_group)
          end
        end
      end

      context 'when `parent_path` is not provided' do
        let(:params) { { include_subgroups: true } }

        it 'has no effect' do
          expect(subject).to contain_exactly(public_group, parent_group, child_group, grandchild_group)
        end
      end
    end

    context 'with `visibility_level` argument' do
      let_it_be(:internal_group) { create(:group, :internal, name: 'internal-group') }

      before_all do
        private_group.add_developer(user)
      end

      context 'when filtering by public visibility' do
        let(:params) { { visibility_level: Gitlab::VisibilityLevel::PUBLIC } }

        it 'returns only public groups' do
          expect(subject).to contain_exactly(public_group)
        end
      end

      context 'when filtering by internal visibility' do
        let(:params) { { visibility_level: Gitlab::VisibilityLevel::INTERNAL } }

        it 'returns only internal groups' do
          expect(subject).to contain_exactly(internal_group)
        end
      end

      context 'when filtering by private visibility' do
        let(:params) { { visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

        it 'returns only accessible private groups' do
          expect(subject).to contain_exactly(private_group)
        end
      end

      context 'when the argument is not provided' do
        it 'returns groups of all visibility levels' do
          expect(subject).to contain_exactly(public_group, internal_group, private_group)
        end
      end
    end

    context 'with `all_available` argument' do
      where :args, :expected_param do
        {}                       | { all_available: true }
        { all_available: nil }   | { all_available: true }
        { all_available: true }  | { all_available: true }
        { all_available: false } | { all_available: false }
      end

      with_them do
        it 'pass the correct parameter to the GroupsFinder' do
          expect(GroupsFinder).to receive(:new)
            .with(user, hash_including(**expected_param)).and_call_original

          resolve(described_class, args: args, lookahead: positive_lookahead, ctx: { current_user: user })
        end
      end
    end

    context 'with marked_for_deletion_on filter', :freeze_time do
      let_it_be(:marked_for_deletion_on) { Date.yesterday }
      let_it_be(:group_marked_for_deletion) do
        create(:group_with_deletion_schedule, marked_for_deletion_on: marked_for_deletion_on, owners: user)
      end

      context 'when a group has been marked for deletion on the given date' do
        let(:params) { { marked_for_deletion_on: marked_for_deletion_on } }

        it { is_expected.to contain_exactly(group_marked_for_deletion) }
      end

      context 'when no groups have been marked for deletion on the given date' do
        let(:params) { { marked_for_deletion_on: (marked_for_deletion_on - 2.days) } }

        it { is_expected.to be_empty }
      end
    end

    context 'with aimed_for_deletion filter' do
      let_it_be(:group_aimed_for_deletion) do
        create(:group_with_deletion_schedule, owners: user)
      end

      let_it_be(:regular_group) do
        create(:group, owners: user)
      end

      context 'when aimed_for_deletion is true' do
        let(:params) { { aimed_for_deletion: true } }

        it 'returns only groups aimed for deletion' do
          expect(subject).to contain_exactly(group_aimed_for_deletion)
        end
      end

      context 'when aimed_for_deletion is false' do
        let(:params) { { aimed_for_deletion: false } }

        it 'returns only groups not aimed for deletion' do
          expect(subject).to contain_exactly(public_group, regular_group)
        end
      end
    end
  end
end
