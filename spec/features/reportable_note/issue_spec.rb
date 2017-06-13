require 'spec_helper'

describe 'Reportable note on issue', :feature, :js do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }
  let!(:note) { create(:note_on_issue, noteable: issue, project: project) }

  before do
    project.add_master(user)
    login_as user

    visit namespace_project_issue_path(project.namespace, project, issue)
  end

  it_behaves_like 'reportable note'
end
