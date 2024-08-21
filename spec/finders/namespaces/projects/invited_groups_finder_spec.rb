# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Projects::InvitedGroupsFinder, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user }
  let_it_be(:another_user) { create(:user) }
  let_it_be(:group) { create(:group, owners: user) }
  let_it_be(:other_group) { create(:group, owners: user, name: "other group") }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:project) { create(:project, owners: user) }
  let(:group_access) { Gitlab::Access::DEVELOPER }
  let(:params) { {} }

  subject(:results) { described_class.new(project, current_user, params).execute }

  before do
    create(:project_group_link, group: group, project: project)
    create(:project_group_link, group: other_group, project: project)
    create(:project_group_link, group: private_group, project: project)
  end

  describe '#execute' do
    context 'when the user has permission to read the group' do
      let(:current_user) { user }

      it 'returns the shared groups which is public or visible to the user' do
        expect(results).to contain_exactly(group, other_group)
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
        group.add_owner(current_user)
        other_group.add_maintainer(current_user)
      end

      let(:params) { { min_access_level: Gitlab::Access::OWNER } }

      it 'filters by minimum access level' do
        expect(results).to contain_exactly(group)
      end
    end

    context 'with include relations filter' do
      let_it_be(:direct_group1) { create(:group, owners: current_user) }
      let_it_be(:direct_group2) { create(:group, owners: current_user) }
      let_it_be(:inherited_group1) { create(:group, owners: current_user) }
      let_it_be(:inherited_group2) { create(:group, owners: current_user) }
      let_it_be(:project1) { create(:project, group: direct_group1, owners: current_user) }

      before do
        create(:project_group_link, group: direct_group2, project: project1)
        create(:group_group_link, shared_group: direct_group1, shared_with_group: inherited_group2)
        create(:group_group_link, shared_group: direct_group1, shared_with_group: inherited_group1)
      end

      subject(:results) { described_class.new(project1, current_user, params).execute }

      context 'when relation is direct' do
        let(:params) { { relation: ["direct"] } }

        it 'returns only direct invited groups' do
          expect(results).to contain_exactly(direct_group2)
        end
      end

      context 'when relation is inherited' do
        let(:params) { { relation: ["inherited"] } }

        it 'returns inherited invited groups' do
          expect(results).to contain_exactly(inherited_group1, inherited_group2)
        end
      end

      context 'when no relation params is present' do
        it 'returns all invited groups' do
          expect(results).to contain_exactly(direct_group2, inherited_group1, inherited_group2)
        end
      end

      context 'when direct and inherited relation params is present' do
        let(:params) { { relation: %w[direct inherited] } }

        it 'returns all invited groups' do
          expect(results).to contain_exactly(direct_group2, inherited_group1, inherited_group2)
        end
      end
    end
  end
end
