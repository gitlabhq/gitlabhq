require 'spec_helper'

describe 'Reportable note on issue', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let!(:note) { create(:note_on_issue, noteable: issue, project: project) }

  before do
    project.add_master(user)
    sign_in(user)

    visit project_issue_path(project, issue)
  end

  it_behaves_like 'reportable note', 'issue'
end
