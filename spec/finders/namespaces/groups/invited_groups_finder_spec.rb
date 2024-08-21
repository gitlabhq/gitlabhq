# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Groups::InvitedGroupsFinder, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user }
  let_it_be(:another_user) { create(:user) }
  let_it_be(:group) { create(:group, :private, owners: user, name: "group") }
  let_it_be(:shared_group) { create(:group, :private, owners: user, name: "shared group") }
  let_it_be(:other_group) { create(:group, :public, owners: user, name: "other group") }
  let_it_be(:another_group) { create(:group, :private, name: "another group") }

  let(:params) { {} }

  subject(:results) { described_class.new(group, current_user, params).execute }

  before do
    create(:group_group_link, shared_group: group, shared_with_group: shared_group)
    create(:group_group_link, shared_group: group, shared_with_group: other_group)
    create(:group_group_link, shared_group: group, shared_with_group: another_group)
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

    context 'with include relations filter' do
      let(:new_group) { create(:group) }
      let(:direct_group) { create(:group) }
      let(:sub_group) { create(:group, parent: new_group) }
      let(:direct_group_2) { create(:group) }

      before do
        create(:group_group_link, shared_group: new_group, shared_with_group: direct_group)
        create(:group_group_link, shared_group: new_group, shared_with_group: sub_group)
        create(:group_group_link, shared_group: sub_group, shared_with_group: direct_group_2)
      end

      subject(:results) { described_class.new(new_group, current_user, params).execute }

      context 'when relation is direct' do
        let(:params) { { relation: ["direct"] } }

        it 'returns only direct invited groups' do
          expect(results).to contain_exactly(direct_group, sub_group)
        end
      end

      context 'when no inherited relation is present' do
        let(:params) { { relation: ["inherited"] } }

        it 'returns no invited groups' do
          expect(results).to be_empty
        end
      end

      context 'when inherited relation is present with respect to sub group' do
        let(:params) { { relation: %w[inherited] } }

        subject(:results) { described_class.new(sub_group, current_user, params).execute }

        it 'returns invited groups' do
          expect(results).to contain_exactly(sub_group, direct_group)
        end
      end

      context 'when direct and inherited relation is present with respect to sub group' do
        let(:params) { { relation: %w[inherited direct] } }

        subject(:results) { described_class.new(sub_group, current_user, params).execute }

        it 'returns all invited groups' do
          expect(results).to contain_exactly(sub_group, direct_group, direct_group_2)
        end
      end
    end
  end
end
