# frozen_string_literal: true

require 'spec_helper'

RSpec
  .describe(
    Projects::MergeRequestsController,
    '(JavaScript fixtures)',
    type: :controller,
    feature_category: :code_review_workflow
  ) do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project) { create(:project, :repository, namespace: namespace, path: 'merge-requests-project') }
  let(:user) { project.first_owner }

  let(:description) do
    <<~MARKDOWN.strip_heredoc
    - [ ] Task List Item
    - [ ]
    - [ ] Task List Item 2
    MARKDOWN
  end

  let(:merge_request) do
    create(
      :merge_request,
      source_project: project,
      target_project: project,
      description: description
    )
  end

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
    build(:text_diff_position, :added,
      file: path,
      new_line: 14,
      diff_refs: merge_request.diff_refs
    )
  end

  render_views

  before do
    sign_in(user)
    allow(Discussion).to receive(:build_discussion_id).and_return(['discussionid:ceterumcenseo'])
  end

  after do
    remove_repository(project)
  end

  it 'merge_requests/merge_request_with_single_assignee_feature.html' do
    stub_licensed_features(multiple_merge_request_assignees: false)

    render_merge_request_edit(merge_request)
  end

  it 'merge_requests/merge_request_of_current_user.html' do
    merge_request.update!(author: user)

    render_merge_request(merge_request)
  end

  it 'merge_requests/merge_request_with_task_list.html' do
    create(:ci_build, :pending, pipeline: pipeline)

    render_merge_request(merge_request)
  end

  it 'merge_requests/diff_comment.html' do
    create(:diff_note_on_merge_request, project: project, author: user, position: position, noteable: merge_request)
    create(:note_on_merge_request, author: user, project: project, noteable: merge_request)
    render_merge_request(merge_request)
  end

  it 'merge_requests/diff_discussion.json' do
    create(:diff_note_on_merge_request, project: project, author: user, position: position, noteable: merge_request)
    render_discussions_json(merge_request)
  end

  it 'merge_requests/resolved_diff_discussion.json' do
    note = create(:discussion_note_on_merge_request, :resolved, project: project, author: user, position: position, noteable: merge_request)
    create(:system_note, project: project, author: user, noteable: merge_request, discussion_id: note.discussion.id)

    render_discussions_json(merge_request)
  end

  context 'with image diff' do
    let(:merge_request2) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, title: "Added images") }
    let(:image_path) { "files/images/ee_repo_logo.png" }
    let(:image_position) do
      build(:image_diff_position,
        file: image_path,
        diff_refs: merge_request2.diff_refs
      )
    end

    it 'merge_requests/image_diff_discussion.json' do
      create(:diff_note_on_merge_request, project: project, noteable: merge_request2, position: image_position)
      render_discussions_json(merge_request2)
    end
  end

  context 'with mentions' do
    let(:group) { create(:group) }
    let(:description) { "@#{group.full_path} @all @#{user.username}" }

    before do
      stub_feature_flags(disable_all_mention: false)
    end

    it 'merge_requests/merge_request_with_mentions.html' do
      render_merge_request(merge_request)
    end
  end

  it 'merge_requests/merge_request_list.html' do
    stub_feature_flags(vue_merge_request_list: false)

    create(:merge_request, source_project: project, target_project: project)

    get :index, params: {
      namespace_id: project.namespace.to_param,
      project_id: project
    }

    expect(response).to be_successful
  end

  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers

    context 'merge request in state readyToMerge query' do
      base_input_path = 'vue_merge_request_widget/queries/states/'
      base_output_path = 'graphql/merge_requests/states/'
      query_name = 'ready_to_merge.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: Gitlab.ee?)

        post_graphql(query, current_user: user, variables: { projectPath: project.full_path, iid: merge_request.iid.to_s })

        expect_graphql_errors_to_be_empty
      end
    end

    context 'merge request with no approvals' do
      base_input_path = 'vue_merge_request_widget/components/approvals/queries/'
      base_output_path = 'graphql/merge_requests/approvals/'
      query_name = 'approvals.query.graphql'

      it "#{base_output_path}#{query_name}_no_approvals.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: Gitlab.ee?)

        post_graphql(query, current_user: user, variables: { projectPath: project.full_path, iid: merge_request.iid.to_s })

        expect_graphql_errors_to_be_empty
      end
    end

    context 'merge request approved by current user' do
      base_input_path = 'vue_merge_request_widget/components/approvals/queries/'
      base_output_path = 'graphql/merge_requests/approvals/'
      query_name = 'approvals.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        merge_request.approved_by_users << user

        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: Gitlab.ee?)

        post_graphql(query, current_user: user, variables: { projectPath: project.full_path, iid: merge_request.iid.to_s })

        expect_graphql_errors_to_be_empty
      end
    end

    context 'merge request approved by multiple users' do
      base_input_path = 'vue_merge_request_widget/components/approvals/queries/'
      base_output_path = 'graphql/merge_requests/approvals/'
      query_name = 'approvals.query.graphql'

      it "#{base_output_path}#{query_name}_multiple_users.json" do
        merge_request.approved_by_users << user
        merge_request.approved_by_users << create(:user)

        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: Gitlab.ee?)

        post_graphql(query, current_user: user, variables: { projectPath: project.full_path, iid: merge_request.iid.to_s })

        expect_graphql_errors_to_be_empty
      end
    end

    context 'merge request in state getState query' do
      base_input_path = 'vue_merge_request_widget/queries/'
      base_output_path = 'graphql/merge_requests/'
      query_name = 'get_state.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(query, current_user: user, variables: { projectPath: project.full_path, iid: merge_request.iid.to_s })

        expect_graphql_errors_to_be_empty
      end
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

  def render_merge_request_edit(merge_request)
    get :edit, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param
    }, format: :html

    expect(response).to be_successful
  end
end
