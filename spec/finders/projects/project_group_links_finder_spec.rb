# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectGroupLinksFinder, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:invited_group) { create(:group) }
    let_it_be(:project_link) { create(:project_group_link, :developer, project: project, group: invited_group) }

    let(:params) { {} }

    subject { described_class.new(project, params).execute }

    it 'returns project link' do
      is_expected.to contain_exactly(project_link)
    end

    context 'with max_access param' do
      let(:params) { { max_access: true } }

      it 'returns project link' do
        is_expected.to contain_exactly(project_link)
      end

      context 'when inherited group link has lower access level' do
        let_it_be(:group_link) do
          create(:group_group_link, :guest, shared_group: group, shared_with_group: invited_group)
        end

        it 'returns project link' do
          is_expected.to contain_exactly(project_link)
        end
      end

      context 'when inherited group link has higher access level' do
        let_it_be(:group_link) do
          create(:group_group_link, :maintainer, shared_group: group, shared_with_group: invited_group)
        end

        it 'does not return project link' do
          is_expected.to be_empty
        end
      end
    end

    context 'with search param' do
      let(:params) { { search: invited_group.name } }

      it 'returns project link' do
        is_expected.to contain_exactly(project_link)
      end

      context 'when search does not match' do
        let(:params) { { search: 'non-existent-group' } }

        it 'returns empty' do
          is_expected.to be_empty
        end
      end
    end
  end
end
