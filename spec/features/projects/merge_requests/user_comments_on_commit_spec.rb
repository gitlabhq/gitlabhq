require 'spec_helper'

describe 'User comments on a commit', :js do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_commit_path(project, sample_commit.id))
  end

  # TODO: https://gitlab.com/gitlab-org/gitlab-ce/issues/45985
  # include_examples 'comment on merge request file'

  it 'prevents RSpec/EmptyExampleGroup' do
  end
end
