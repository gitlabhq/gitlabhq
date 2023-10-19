# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequests::ConflictsController, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:user)    { project.first_owner }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_with_conflicts) do
    create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start', source_project: project, merge_status: :unchecked) do |mr|
      mr.mark_as_unmergeable
    end
  end

  before do
    sign_in(user)
  end

  describe 'GET show' do
    context 'when the request is html' do
      before do
        allow(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_loading_conflict_ui_action)

        get :show, params: {
          namespace_id: merge_request_with_conflicts.project.namespace.to_param,
          project_id: merge_request_with_conflicts.project,
          id: merge_request_with_conflicts.iid
        }, format: 'html'
      end

      it 'does tracks the resolve call' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to have_received(:track_loading_conflict_ui_action).with(user: user)
      end
    end

    context 'when the conflicts cannot be resolved in the UI' do
      before do
        allow(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_loading_conflict_ui_action)

        allow(Gitlab::Git::Conflict::Parser).to receive(:parse)
          .and_raise(Gitlab::Git::Conflict::Parser::UnmergeableFile)

        get :show, params: {
          namespace_id: merge_request_with_conflicts.project.namespace.to_param,
          project_id: merge_request_with_conflicts.project,
          id: merge_request_with_conflicts.iid
        }, format: 'json'
      end

      it 'returns a 200 status code' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns JSON with a message' do
        expect(json_response.keys).to contain_exactly('message', 'type')
      end

      it 'does not track the resolve call' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to have_received(:track_loading_conflict_ui_action).with(user: user)
      end
    end

    context 'with valid conflicts' do
      before do
        get :show, params: {
          namespace_id: merge_request_with_conflicts.project.namespace.to_param,
          project_id: merge_request_with_conflicts.project,
          id: merge_request_with_conflicts.iid
        }, format: 'json'
      end

      it 'matches the schema' do
        expect(response).to match_response_schema('conflicts')
      end

      it 'includes meta info about the MR' do
        expect(json_response['commit_message']).to include('Merge branch')
        expect(json_response['commit_sha']).to match(/\h{40}/)
        expect(json_response['source_branch']).to eq(merge_request_with_conflicts.source_branch)
        expect(json_response['target_branch']).to eq(merge_request_with_conflicts.target_branch)
      end

      it 'includes each file that has conflicts' do
        filenames = json_response['files'].pluck('new_path')

        expect(filenames).to contain_exactly('files/ruby/popen.rb', 'files/ruby/regex.rb')
      end

      it 'splits files into sections with lines' do
        json_response['files'].each do |file|
          file['sections'].each do |section|
            expect(section).to include('conflict', 'lines')

            section['lines'].each do |line|
              if section['conflict']
                expect(line['type']).to be_in(%w[old new])
                expect(line.values_at('old_line', 'new_line')).to contain_exactly(nil, a_kind_of(Integer))
              elsif line['type'].nil?
                expect(line['old_line']).not_to eq(nil)
                expect(line['new_line']).not_to eq(nil)
              else
                expect(line['type']).to eq('match')
                expect(line['old_line']).to eq(nil)
                expect(line['new_line']).to eq(nil)
              end
            end
          end
        end
      end

      it 'has unique section IDs across files' do
        section_ids = json_response['files'].flat_map do |file|
          file['sections'].pluck('id').compact
        end

        expect(section_ids.uniq).to eq(section_ids)
      end
    end
  end

  describe 'GET conflict_for_path' do
    def conflict_for_path(path)
      get :conflict_for_path, params: {
        namespace_id: merge_request_with_conflicts.project.namespace.to_param,
        project_id: merge_request_with_conflicts.project,
        id: merge_request_with_conflicts.iid,
        old_path: path,
        new_path: path
      }, format: 'json'
    end

    context 'when the conflicts cannot be resolved in the UI' do
      before do
        allow(Gitlab::Git::Conflict::Parser).to receive(:parse)
          .and_raise(Gitlab::Git::Conflict::Parser::UnmergeableFile)

        conflict_for_path('files/ruby/regex.rb')
      end

      it 'returns a 404 status code' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the file does not exist cannot be resolved in the UI' do
      before do
        conflict_for_path('files/ruby/regexp.rb')
      end

      it 'returns a 404 status code' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an existing file' do
      let(:path) { 'files/ruby/regex.rb' }

      before do
        conflict_for_path(path)
      end

      it 'returns a 200 and the file in JSON format' do
        content = MergeRequests::Conflicts::ListService.new(merge_request_with_conflicts)
                    .file_for_path(path, path)
                    .content

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include(
            'old_path' => path,
            'new_path' => path,
            'blob_icon' => 'doc-text',
            'blob_path' => a_string_ending_with(path),
            'content' => content
          )
        end
      end
    end
  end

  context 'POST resolve_conflicts' do
    let!(:original_head_sha) { merge_request_with_conflicts.diff_head_sha }

    before do
      allow(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_resolve_conflict_action)
    end

    def resolve_conflicts(files)
      post :resolve_conflicts, params: {
        namespace_id: merge_request_with_conflicts.project.namespace.to_param,
        project_id: merge_request_with_conflicts.project,
        id: merge_request_with_conflicts.iid,
        files: files,
        commit_message: 'Commit message'
      }, format: 'json'
    end

    context 'with valid params' do
      before do
        resolved_files = [
          {
            'new_path' => 'files/ruby/popen.rb',
            'old_path' => 'files/ruby/popen.rb',
            'sections' => {
              '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head'
            }
          }, {
            'new_path' => 'files/ruby/regex.rb',
            'old_path' => 'files/ruby/regex.rb',
            'sections' => {
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
            }
          }
        ]

        resolve_conflicts(resolved_files)
      end

      it 'handles the success case' do
        aggregate_failures do
          # creates a new commit on the branch
          expect(original_head_sha).not_to eq(merge_request_with_conflicts.source_branch_head.sha)
          expect(merge_request_with_conflicts.source_branch_head.message).to include('Commit message')

          expect(response).to have_gitlab_http_status(:ok)
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to have_received(:track_resolve_conflict_action).with(user: user)
        end
      end
    end

    context 'when sections are missing' do
      before do
        resolved_files = [
          {
            'new_path' => 'files/ruby/popen.rb',
            'old_path' => 'files/ruby/popen.rb',
            'sections' => {
              '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head'
            }
          }, {
            'new_path' => 'files/ruby/regex.rb',
            'old_path' => 'files/ruby/regex.rb',
            'sections' => {
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head'
            }
          }
        ]

        resolve_conflicts(resolved_files)
      end

      it 'handles the error case' do
        aggregate_failures do
          # has a message with the name of the first missing section
          expect(json_response['message']).to include('6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21')
          # does not create a new commit
          expect(original_head_sha).to eq(merge_request_with_conflicts.source_branch_head.sha)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to have_received(:track_resolve_conflict_action).with(user: user)
        end
      end
    end

    context 'when files are missing' do
      before do
        resolved_files = [
          {
            'new_path' => 'files/ruby/regex.rb',
            'old_path' => 'files/ruby/regex.rb',
            'sections' => {
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
            }
          }
        ]

        resolve_conflicts(resolved_files)
      end

      it 'handles the error case' do
        aggregate_failures do
          # has a message with the name of the missing file
          expect(json_response['message']).to include('files/ruby/popen.rb')
          # does not create a new commit
          expect(original_head_sha).to eq(merge_request_with_conflicts.source_branch_head.sha)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to have_received(:track_resolve_conflict_action).with(user: user)
        end
      end
    end

    context 'when a file has identical content to the conflict' do
      before do
        content = MergeRequests::Conflicts::ListService.new(merge_request_with_conflicts)
                    .file_for_path('files/ruby/popen.rb', 'files/ruby/popen.rb')
                    .content

        resolved_files = [
          {
            'new_path' => 'files/ruby/popen.rb',
            'old_path' => 'files/ruby/popen.rb',
            'content' => content
          }, {
            'new_path' => 'files/ruby/regex.rb',
            'old_path' => 'files/ruby/regex.rb',
            'sections' => {
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
            }
          }
        ]

        resolve_conflicts(resolved_files)
      end

      it 'handles the error case' do
        aggregate_failures do
          # has a message with the path of the problem file
          expect(json_response['message']).to include('files/ruby/popen.rb')
          # does not create a new commit
          expect(original_head_sha).to eq(merge_request_with_conflicts.source_branch_head.sha)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to have_received(:track_resolve_conflict_action).with(user: user)
        end
      end
    end
  end
end
