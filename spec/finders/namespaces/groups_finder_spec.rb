# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::GroupsFinder, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:public_group) { create(:group, :public, name: 'public-group') }
  let_it_be(:internal_group) { create(:group, :internal, name: 'internal-group') }
  let_it_be(:private_group) { create(:group, :private, name: 'private-group') }
  let_it_be(:member_group) { create(:group, :private, name: 'member-group') }
  let_it_be(:subgroup) { create(:group, :public, parent: public_group, name: 'public-subgroup') }

  before_all do
    member_group.add_developer(user)
  end

  describe '#execute' do
    let(:current_user) { user }

    context 'with no params' do
      let(:params) { {} }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'
    end

    context 'with a search term' do
      let(:params) { { search: 'member' } }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'

      it 'returns the matching group' do
        expect(described_class.new(current_user, params).execute).to include(member_group)
      end
    end

    context 'with all_available false' do
      let(:params) { { all_available: false } }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'
    end

    context 'with owned' do
      let(:params) { { owned: true } }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'
    end

    context 'with min_access_level' do
      let(:params) { { min_access_level: Gitlab::Access::DEVELOPER } }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'
    end

    context 'with top_level_only' do
      let(:params) { { top_level_only: true } }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'
    end

    context 'with visibility' do
      let(:params) { { visibility: Gitlab::VisibilityLevel::PUBLIC } }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'
    end

    context 'with ids' do
      let(:params) { { ids: [public_group.id] } }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'
    end

    context 'with exclude_group_ids' do
      let(:params) { { exclude_group_ids: [public_group.id] } }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'
    end

    context 'when the user is anonymous' do
      let(:current_user) { nil }
      let(:params) { {} }

      it_behaves_like 'a finder returning the same groups as GroupsFinder'

      it 'does not return private groups' do
        expect(described_class.new(current_user, params).execute).not_to include(private_group, member_group)
      end
    end
  end

  # Controllers hand finders ActionController::Parameters, and GroupsFinder takes them
  # untouched, so neither shape may raise here.
  describe 'with ActionController::Parameters' do
    it 'accepts unpermitted params' do
      params = ActionController::Parameters.new(search: 'member')

      expect(described_class.new(user, params).execute).to include(member_group)
    end

    it 'accepts permitted params' do
      params = ActionController::Parameters.new(search: 'member').permit(:search)

      expect(described_class.new(user, params).execute).to include(member_group)
    end

    it 'resolves parent_id' do
      params = ActionController::Parameters.new(parent_id: public_group.id)

      expect(described_class.new(user, params).execute).to contain_exactly(subgroup)
    end
  end

  describe 'parent' do
    it 'scopes to the given group' do
      expect(described_class.new(user, parent: public_group).execute).to contain_exactly(subgroup)
    end

    it 'matches GroupsFinder' do
      expected = GroupsFinder.new(user, parent: public_group).execute

      expect(described_class.new(user, parent: public_group).execute).to match_array(expected)
    end

    # GroupsFinder itself ignores parent_id, so this finder resolves it and authorizes it.
    context 'with parent_id' do
      it 'resolves it to a Group and scopes the query' do
        expect(described_class.new(user, parent_id: public_group.id).execute).to contain_exactly(subgroup)
      end

      it 'matches what passing the Group directly returns' do
        expected = described_class.new(user, parent: public_group).execute

        expect(described_class.new(user, parent_id: public_group.id).execute).to match_array(expected)
      end

      context 'when the user cannot read it' do
        let_it_be(:hidden_parent) { create(:group, :private) }
        let_it_be(:hidden_child) { create(:group, :private, parent: hidden_parent) }

        it 'returns nothing rather than widening to every visible group' do
          expect(described_class.new(user, parent_id: hidden_parent.id).execute).to be_empty
        end
      end

      context 'when it does not exist' do
        it 'returns nothing' do
          expect(described_class.new(user, parent_id: non_existing_record_id).execute).to be_empty
        end
      end
    end
  end
end
