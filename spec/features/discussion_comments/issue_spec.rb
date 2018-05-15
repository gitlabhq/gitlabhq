require 'spec_helper'

describe 'Discussion Comments Issue', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }

  before do
    project.add_master(user)
    sign_in(user)

    visit project_issue_path(project, issue)
  end

  # TODO: https://gitlab.com/gitlab-org/gitlab-ce/issues/45985
  # it_behaves_like 'discussion comments', 'issue'

  it 'prevents RSpec/EmptyExampleGroup' do
  end
end
