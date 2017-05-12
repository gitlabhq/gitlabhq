require 'spec_helper'

describe 'Subgroup Issuables', :feature, :js do
  let!(:parent_group) { create(:group, name: 'parentgroup') }
  let!(:subgroup) { create(:group, parent: parent_group, name: 'subgroup') }
  let!(:project) { create(:empty_project, namespace: subgroup, name: 'project') }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    login_as user
  end

  context 'empty issues index' do
    before do
      visit namespace_project_issues_path(project.namespace, project)
    end

    it_behaves_like 'has subgroup title', 'parentgroup', 'subgroup', 'project'
  end

  context 'empty merge request index' do
    before do
      visit namespace_project_merge_requests_path(project.namespace, project)
    end

    it_behaves_like 'has subgroup title', 'parentgroup', 'subgroup', 'project'
  end
end
