# frozen_string_literal: true

require 'spec_helper'

describe Projects::MergeRequestsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'merge-requests-project') }

  # rubocop: disable Layout/TrailingWhitespace
  let(:merge_request) do
    create(
      :merge_request,
      :with_diffs,
      source_project: project,
      target_project: project,
      description: <<~MARKDOWN.strip_heredoc
      - [ ] Task List Item
      - [ ]   
      - [ ] Task List Item 2
      MARKDOWN
    )
  end
  # rubocop: enable Layout/TrailingWhitespace

  let(:merged_merge_request) { create(:merge_request, :merged, source_project: project, target_project: project) }
  let(:pipeline) do
    create(
      :ci_pipeline,
      project: merge_request.source_project,
      ref: merge_request.source_branch,
      sha: merge_request.diff_head_sha
    )
  end
  let(:path) { "files/ruby/popen.rb" }
  let(:position) do
    Gitlab::Diff::Position.new(
      old_path: path,
      new_path: path,
      old_line: nil,
      new_line: 14,
      diff_refs: merge_request.diff_refs
    )
  end

  render_views

  before(:all) do
    clean_frontend_fixtures('merge_requests/')
  end

  before do
    sign_in(admin)
    allow(Discussion).to receive(:build_discussion_id).and_return(['discussionid:ceterumcenseo'])
  end

  after do
    remove_repository(project)
  end

  it 'merge_requests/merge_request_of_current_user.html' do
    merge_request.update(author: admin)

    render_merge_request(merge_request)
  end

  it 'merge_requests/merge_request_with_task_list.html' do
    create(:ci_build, :pending, pipeline: pipeline)

    render_merge_request(merge_request)
  end

  it 'merge_requests/merged_merge_request.html' do
    expect_next_instance_of(MergeRequest) do |merge_request|
      allow(merge_request).to receive(:source_branch_exists?).and_return(true)
      allow(merge_request).to receive(:can_remove_source_branch?).and_return(true)
    end
    render_merge_request(merged_merge_request)
  end

  it 'merge_requests/diff_comment.html' do
    create(:diff_note_on_merge_request, project: project, author: admin, position: position, noteable: merge_request)
    create(:note_on_merge_request, author: admin, project: project, noteable: merge_request)
    render_merge_request(merge_request)
  end

  it 'merge_requests/merge_request_with_comment.html' do
    create(:note_on_merge_request, author: admin, project: project, noteable: merge_request, note: '- [ ] Task List Item')
    render_merge_request(merge_request)
  end

  it 'merge_requests/discussions.json' do
    create(:diff_note_on_merge_request, project: project, author: admin, position: position, noteable: merge_request)
    render_discussions_json(merge_request)
  end

  it 'merge_requests/diff_discussion.json' do
    create(:diff_note_on_merge_request, project: project, author: admin, position: position, noteable: merge_request)
    render_discussions_json(merge_request)
  end

  it 'merge_requests/resolved_diff_discussion.json' do
    note = create(:discussion_note_on_merge_request, :resolved, project: project, author: admin, position: position, noteable: merge_request)
    create(:system_note, project: project, author: admin, noteable: merge_request, discussion_id: note.discussion.id)

    render_discussions_json(merge_request)
  end

  context 'with image diff' do
    let(:merge_request2) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, title: "Added images") }
    let(:image_path) { "files/images/ee_repo_logo.png" }
    let(:image_position) do
      Gitlab::Diff::Position.new(
        old_path: image_path,
        new_path: image_path,
        width: 100,
        height: 100,
        x: 1,
        y: 1,
        position_type: "image",
        diff_refs: merge_request2.diff_refs
      )
    end

    it 'merge_requests/image_diff_discussion.json' do
      create(:diff_note_on_merge_request, project: project, noteable: merge_request2, position: image_position)
      render_discussions_json(merge_request2)
    end
  end

  private

  def render_discussions_json(merge_request)
    get :discussions, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param
    }, format: :json
  end

  def render_merge_request(merge_request)
    get :show, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param
    }, format: :html

    expect(response).to be_successful
  end
end
