# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a commit', :js, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(project_commit_path(project, sample_commit.id))
  end

  include_examples 'comment on merge request file'
end
