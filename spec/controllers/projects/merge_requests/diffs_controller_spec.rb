# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequests::DiffsController do
  include ProjectForksHelper

  shared_examples '404 for unexistent diffable' do
    context 'when diffable does not exists' do
      it 'returns 404' do
        go(diff_id: non_existing_record_id)

        expect(MergeRequestDiff.find_by(id: non_existing_record_id)).to be_nil
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the merge_request_diff.id is blank' do
      it 'returns 404' do
        allow_next_instance_of(MergeRequest) do |instance|
          allow(instance).to receive(:merge_request_diff).and_return(MergeRequestDiff.new(merge_request_id: instance.id))

          go

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  shared_examples 'forked project with submodules' do
    render_views

    let(:project) { create(:project, :repository) }
    let(:forked_project) { fork_project_with_submodules(project) }
    let(:merge_request) { create(:merge_request_with_diffs, source_project: forked_project, source_branch: 'add-submodule-version-bump', target_branch: 'master', target_project: project) }

    before do
      project.add_developer(user)

      merge_request.reload
      go
    end

    it 'renders' do
      expect(response).to be_successful
      expect(response.body).to have_content('Subproject commit')
    end
  end

  shared_examples 'cached diff collection' do
    it 'ensures diff highlighting cache writing' do
      expect_next_instance_of(Gitlab::Diff::HighlightCache) do |cache|
        expect(cache).to receive(:write_if_empty).once
      end

      go
    end
  end

  shared_examples "diff note on-demand position creation" do
    it "updates diff discussion positions" do
      service = double("service")

      expect(Discussions::CaptureDiffNotePositionsService).to receive(:new).with(merge_request).and_return(service)
      expect(service).to receive(:execute)

      go
    end
  end

  shared_examples 'show the right diff files with previous diff_id' do
    context 'with previous diff_id' do
      let!(:merge_request_diff_1) { merge_request.merge_request_diffs.create!(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
      let!(:merge_request_diff_2) { merge_request.merge_request_diffs.create!(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e', diff_type: :merge_head) }

      subject { go(diff_id: merge_request_diff_1.id, diff_head: true) }

      it 'shows the right diff files' do
        subject
        expect(json_response["diff_files"].size).to eq(merge_request_diff_1.files_count)
      end
    end
  end

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET show' do
    def go(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        format: 'json'
      }

      get :show, params: params.merge(extra_params)
    end

    context 'with default params' do
      context 'for the same project' do
        before do
          allow(controller).to receive(:rendered_for_merge_request?).and_return(true)
        end

        it 'serializes merge request diff collection' do
          expect_next_instance_of(DiffsSerializer) do |instance|
            expect(instance).to receive(:represent).with(an_instance_of(Gitlab::Diff::FileCollection::MergeRequestDiff), an_instance_of(Hash))
          end

          go
        end
      end

      context 'when note is a legacy diff note' do
        before do
          create(:legacy_diff_note_on_merge_request, project: project, noteable: merge_request)
        end

        it 'serializes merge request diff collection' do
          expect_next_instance_of(DiffsSerializer) do |instance|
            expect(instance).to receive(:represent).with(an_instance_of(Gitlab::Diff::FileCollection::MergeRequestDiff), an_instance_of(Hash))
          end

          go
        end
      end

      it_behaves_like 'forked project with submodules'
    end

    it_behaves_like 'cached diff collection'
    it_behaves_like 'diff note on-demand position creation'
  end

  describe 'GET diffs_metadata' do
    def go(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        format: 'json'
      }

      get :diffs_metadata, params: params.merge(extra_params)
    end

    it_behaves_like '404 for unexistent diffable'

    it_behaves_like 'show the right diff files with previous diff_id'

    context 'when not authorized' do
      let(:another_user) { create(:user) }

      before do
        sign_in(another_user)
      end

      it 'returns 404 when not a member' do
        go

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 404 when visibility level is not enough' do
        project.add_guest(another_user)

        go

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with valid diff_id' do
      it 'returns success' do
        go(diff_id: merge_request.merge_request_diff.id)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'serializes diffs metadata with expected arguments' do
        expected_options = {
          environment: nil,
          merge_request: merge_request,
          merge_request_diff: merge_request.merge_request_diff,
          merge_request_diffs: merge_request.merge_request_diffs,
          start_version: nil,
          start_sha: nil,
          commit: nil,
          latest_diff: true,
          only_context_commits: false
        }

        expect_next_instance_of(DiffsMetadataSerializer) do |instance|
          expect(instance).to receive(:represent)
            .with(an_instance_of(Gitlab::Diff::FileCollection::MergeRequestDiff), expected_options)
            .and_call_original
        end

        go(diff_id: merge_request.merge_request_diff.id)
      end
    end

    context "with the :default_merge_ref_for_diffs flag on" do
      let(:diffable_merge_ref) { true }

      subject do
        go(diff_head: true,
           diff_id: merge_request.merge_request_diff.id,
           start_sha: merge_request.merge_request_diff.start_commit_sha)
      end

      it "correctly generates the right diff between versions" do
        MergeRequests::MergeToRefService.new(project: project, current_user: merge_request.author).execute(merge_request)

        expect_next_instance_of(CompareService) do |service|
          expect(service).to receive(:execute).with(
            project,
            merge_request.merge_request_diff.head_commit_sha,
            straight: true)
        end

        subject
      end
    end

    context 'with diff_head param passed' do
      before do
        allow(merge_request).to receive(:diffable_merge_ref?)
          .and_return(diffable_merge_ref)
      end

      context 'the merge request can be compared with head' do
        let(:diffable_merge_ref) { true }

        it 'compares diffs with the head' do
          create(:merge_request_diff, :merge_head, merge_request: merge_request)

          go(diff_head: true)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'the merge request cannot be compared with head' do
        let(:diffable_merge_ref) { false }

        it 'compares diffs with the base' do
          go(diff_head: true)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with MR regular diff params' do
      it 'returns success' do
        go

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'serializes diffs metadata with expected arguments' do
        expected_options = {
          environment: nil,
          merge_request: merge_request,
          merge_request_diff: merge_request.merge_request_diff,
          merge_request_diffs: merge_request.merge_request_diffs,
          start_version: nil,
          start_sha: nil,
          commit: nil,
          latest_diff: true,
          only_context_commits: false
        }

        expect_next_instance_of(DiffsMetadataSerializer) do |instance|
          expect(instance).to receive(:represent)
            .with(an_instance_of(Gitlab::Diff::FileCollection::MergeRequestDiff), expected_options)
            .and_call_original
        end

        go
      end
    end

    context 'with commit param' do
      it 'returns success' do
        go(commit_id: merge_request.diff_head_sha)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'serializes diffs metadata with expected arguments' do
        expected_options = {
          environment: nil,
          merge_request: merge_request,
          merge_request_diff: nil,
          merge_request_diffs: merge_request.merge_request_diffs,
          start_version: nil,
          start_sha: nil,
          commit: merge_request.diff_head_commit,
          latest_diff: nil,
          only_context_commits: false
        }

        expect_next_instance_of(DiffsMetadataSerializer) do |instance|
          expect(instance).to receive(:represent)
            .with(an_instance_of(Gitlab::Diff::FileCollection::Commit), expected_options)
            .and_call_original
        end

        go(commit_id: merge_request.diff_head_sha)
      end
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        format: 'json'
      }

      get :diff_for_path, params: params.merge(extra_params)
    end

    let(:existing_path) { 'files/ruby/popen.rb' }

    context 'when the merge request exists' do
      context 'when the user can view the merge request' do
        context 'when the path exists in the diff' do
          it 'enables diff notes' do
            diff_for_path(old_path: existing_path, new_path: existing_path)

            expect(assigns(:diff_notes_disabled)).to be_falsey
            expect(assigns(:new_diff_note_attrs)).to eq(noteable_type: 'MergeRequest',
                                                        noteable_id: merge_request.id,
                                                        commit_id: nil)
          end

          it 'only renders the diffs for the path given' do
            diff_for_path(old_path: existing_path, new_path: existing_path)

            paths = json_response['diff_files'].map { |file| file['new_path'] }

            expect(paths).to include(existing_path)
          end
        end
      end

      context 'when the user cannot view the merge request' do
        before do
          project.team.truncate
          diff_for_path(old_path: existing_path, new_path: existing_path)
        end

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when the merge request does not exist' do
      before do
        diff_for_path(id: merge_request.iid.succ, old_path: existing_path, new_path: existing_path)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the merge request belongs to a different project' do
      let(:other_project) { create(:project) }

      before do
        other_project.add_maintainer(user)
        diff_for_path(old_path: existing_path, new_path: existing_path, project_id: other_project)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET diffs_batch' do
    shared_examples_for 'serializes diffs with expected arguments' do
      it 'serializes paginated merge request diff collection' do
        expect_next_instance_of(PaginatedDiffSerializer) do |instance|
          expect(instance).to receive(:represent)
            .with(an_instance_of(collection), expected_options)
            .and_call_original
        end

        subject
      end
    end

    shared_examples_for 'successful request' do
      it 'returns success' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'tracks mr_diffs event' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_mr_diffs_action)
          .with(merge_request: merge_request)

        subject
      end

      context 'when DNT is enabled' do
        before do
          request.headers['DNT'] = '1'
        end

        it 'does not track any mr_diffs event' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .not_to receive(:track_mr_diffs_action)

          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .not_to receive(:track_mr_diffs_single_file_action)

          subject
        end
      end

      context 'when user has view_diffs_file_by_file set to false' do
        before do
          user.update!(view_diffs_file_by_file: false)
        end

        it 'does not track single_file_diffs events' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .not_to receive(:track_mr_diffs_single_file_action)

          subject
        end
      end

      context 'when user has view_diffs_file_by_file set to true' do
        before do
          user.update!(view_diffs_file_by_file: true)
        end

        it 'tracks single_file_diffs events' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_mr_diffs_single_file_action)
            .with(merge_request: merge_request, user: user)

          subject
        end
      end
    end

    def collection_arguments(pagination_data = {})
      {
        environment: nil,
        merge_request: merge_request,
        diff_view: :inline,
        merge_ref_head_diff: nil,
        pagination_data: {
          total_pages: nil
        }.merge(pagination_data)
      }
    end

    def go(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        page: 0,
        per_page: 20,
        format: 'json'
      }

      get :diffs_batch, params: params.merge(extra_params)
    end

    it_behaves_like '404 for unexistent diffable'

    it_behaves_like 'show the right diff files with previous diff_id'

    context 'when not authorized' do
      let(:other_user) { create(:user) }

      before do
        sign_in(other_user)
      end

      it 'returns 404' do
        go

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with valid diff_id' do
      subject { go(diff_id: merge_request.merge_request_diff.id) }

      it_behaves_like 'serializes diffs with expected arguments' do
        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) { collection_arguments(total_pages: 20).merge(merge_ref_head_diff: false) }
      end

      it_behaves_like 'successful request'
    end

    context 'with commit_id param' do
      subject { go(commit_id: merge_request.diff_head_sha) }

      it_behaves_like 'serializes diffs with expected arguments' do
        let(:collection) { Gitlab::Diff::FileCollection::Commit }
        let(:expected_options) { collection_arguments }
      end
    end

    context 'with diff_id and start_sha params' do
      subject do
        go(diff_id: merge_request.merge_request_diff.id,
           start_sha: merge_request.merge_request_diff.start_commit_sha)
      end

      it_behaves_like 'serializes diffs with expected arguments' do
        let(:collection) { Gitlab::Diff::FileCollection::Compare }
        let(:expected_options) { collection_arguments.merge(merge_ref_head_diff: false) }
      end

      it_behaves_like 'successful request'
    end

    context 'with paths param' do
      let(:example_file_path) { "README" }
      let(:file_path_option) { { paths: [example_file_path] } }

      subject do
        go(file_path_option)
      end

      it_behaves_like 'serializes diffs with expected arguments' do
        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) do
          collection_arguments(total_pages: 20)
        end
      end

      it_behaves_like 'successful request'

      it 'filters down the response to the expected file path' do
        subject

        expect(json_response["diff_files"].size).to eq(1)
        expect(json_response["diff_files"].first["file_path"]).to eq(example_file_path)
      end
    end

    context 'with default params' do
      subject { go }

      it_behaves_like 'serializes diffs with expected arguments' do
        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) { collection_arguments(total_pages: 20) }
      end

      it_behaves_like 'successful request'
    end

    context 'with smaller diff batch params' do
      subject { go(page: 5, per_page: 5) }

      it_behaves_like 'serializes diffs with expected arguments' do
        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) { collection_arguments(total_pages: 20) }
      end

      it_behaves_like 'successful request'
    end

    it_behaves_like 'forked project with submodules'
    it_behaves_like 'cached diff collection'

    context 'diff unfolding' do
      let!(:unfoldable_diff_note) do
        create(:diff_note_on_merge_request, :folded_position, project: project, noteable: merge_request)
      end

      let!(:diff_note) do
        create(:diff_note_on_merge_request, project: project, noteable: merge_request)
      end

      it 'unfolds correct diff file positions' do
        expect_next_instance_of(Gitlab::Diff::FileCollection::MergeRequestDiffBatch) do |instance|
          expect(instance)
            .to receive(:unfold_diff_files)
            .with([unfoldable_diff_note.position])
            .and_call_original
        end

        go
      end
    end
  end
end
