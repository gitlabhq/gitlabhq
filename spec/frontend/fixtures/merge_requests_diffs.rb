# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequests::DiffsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project) { create(:project, :repository, namespace: namespace, path: 'merge-requests-project') }
  let(:user) { project.first_owner }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project, description: '- [ ] Task List Item') }
  let(:path) { "files/ruby/popen.rb" }
  let(:position) do
    build(:text_diff_position, :added,
      file: path,
      new_line: 14,
      diff_refs: merge_request.diff_refs
    )
  end

  render_views

  before do
    # Create a user that matches the project.commit author
    # This is so that the "author" information will be populated
    create(:user, email: project.commit.author_email, name: project.commit.author_name)

    sign_in(user)
  end

  after do
    remove_repository(project)
  end

  it 'merge_request_diffs/with_commit.json' do
    render_merge_request(merge_request, commit_id: project.commit.sha)
  end

  it 'merge_request_diffs/diffs_metadata.json' do
    render_merge_request(merge_request, action: :diffs_metadata)
  end

  it 'merge_request_diffs/diffs_batch.json' do
    render_merge_request(merge_request, action: :diffs_batch, page: 1, per_page: 30)
  end

  private

  def render_merge_request(merge_request, action: :show, view: 'inline', **extra_params)
    get action, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param,
      view: view,
      **extra_params
    }, format: :json

    expect(response).to be_successful
  end
end
