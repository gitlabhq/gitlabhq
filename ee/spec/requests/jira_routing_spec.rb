require 'rails_helper'

describe 'Jira referenced paths', type: :request do
  let(:group) { create(:group, name: 'group') }
  let(:sub_group) { create(:group, name: 'subgroup', parent: group) }

  let(:group_project) { create(:project, name: 'group_project', namespace: group) }
  let(:sub_group_project) { create(:project, name: 'sub_group_project', namespace: sub_group) }

  before do
    login_as user
  end

  describe 'redirects to projects#show' do
    context 'without nested group' do
      let(:user) { group_project.creator }

      it 'redirects to project' do
        get('/-/jira/group/group_project')

        expect(response).to redirect_to('/group/group_project')
      end
    end

    context 'with nested group' do
      let(:user) { sub_group_project.creator }

      it 'redirects to project for root group' do
        get('/-/jira/group/group@sub_group@sub_group_project')

        expect(response).to redirect_to('/group/sub_group/sub_group_project')
      end

      it 'redirects to project for nested group' do
        get('/-/jira/group@sub_group/group@sub_group@sub_group_project')

        expect(response).to redirect_to('/group/sub_group/sub_group_project')
      end
    end
  end

  describe 'redirects to projects/commit#show' do
    context 'without nested group' do
      let(:user) { group_project.creator }

      it 'redirects to commits' do
        get('/-/jira/group/group_project/commit/1234567')

        expect(response).to redirect_to('/group/group_project/commit/1234567')
      end
    end

    context 'with nested group' do
      let(:user) { sub_group_project.creator }

      it 'redirects to commits' do
        get('/-/jira/group/group@sub_group@sub_group_project/commit/1234567')

        expect(response).to redirect_to('/group/sub_group/sub_group_project/commit/1234567')
      end
    end
  end

  describe 'redirects to projects/tree#show' do
    context 'without nested group' do
      let(:user) { group_project.creator }

      it 'redirects to tree' do
        get('/-/jira/group/group_project/tree/1234567')

        expect(response).to redirect_to('/group/group_project/tree/1234567')
      end
    end

    context 'with nested group' do
      let(:user) { sub_group_project.creator }

      it 'redirects to tree' do
        get('/-/jira/group/group@sub_group@sub_group_project/tree/1234567')

        expect(response).to redirect_to('/group/sub_group/sub_group_project/tree/1234567')
      end
    end
  end
end
