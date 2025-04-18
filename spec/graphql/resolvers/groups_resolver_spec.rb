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

    subject { resolve(described_class, args: params, ctx: { current_user: user }) }

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

          resolve(described_class, args: args, ctx: { current_user: user })
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
  end
end
