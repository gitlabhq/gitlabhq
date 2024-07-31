# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Groups::SharedGroupsFinder, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }
  let_it_be(:current_user) { user }
  let_it_be(:group) { create(:group, :private, owners: user, name: "group") }
  let_it_be(:shared_group) { create(:group, :private, name: "shared group") }
  let_it_be(:other_group) { create(:group, :public, name: "other group") }

  let(:params) { {} }

  subject(:results) { described_class.new(group, current_user, params).execute }

  before do
    create(:group_group_link, shared_group: shared_group, shared_with_group: group)
    create(:group_group_link, shared_group: other_group, shared_with_group: group)
  end

  describe '#execute' do
    context 'when the user has permission to read the group' do
      let(:current_user) { user }

      it 'returns the shared groups which is public or visible to the user' do
        expect(results).to contain_exactly(shared_group, other_group)
      end
    end

    context 'when the user does not have permission to read the group' do
      let(:current_user) { another_user }

      it 'returns no groups' do
        expect(results).to be_empty
      end
    end

    context 'with search filter' do
      let(:params) { { search: "other group" } }

      it 'filters by search term' do
        expect(results).to contain_exactly(other_group)
      end
    end

    context 'with visibility filter' do
      let(:params) { { visibility: 'private' } }

      it 'filters by visibility' do
        expect(results).to contain_exactly(shared_group)
      end
    end

    context 'with min_access_level filter' do
      before_all do
        shared_group.add_owner(current_user)
        other_group.add_owner(current_user)
      end

      let(:params) { { min_access_level: Gitlab::Access::OWNER } }

      it 'filters by minimum access level' do
        expect(results).to contain_exactly(shared_group, other_group)
      end
    end
  end
end
