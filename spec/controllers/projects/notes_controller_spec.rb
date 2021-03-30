# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::NotesController do
  include ProjectForksHelper

  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:issue)   { create(:issue, project: project) }
  let(:note)    { create(:note, noteable: issue, project: project) }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      id: note
    }
  end

  describe 'GET index' do
    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        target_type: 'issue',
        target_id: issue.id,
        format: 'json'
      }
    end

    let(:parsed_response) { json_response.with_indifferent_access }
    let(:note_json) { parsed_response[:notes].first }

    before do
      sign_in(user)
      project.add_developer(user)
    end

    it 'passes last_fetched_at from headers to NotesFinder and MergeIntoNotesService' do
      last_fetched_at = Time.zone.at(3.hours.ago.to_i) # remove nanoseconds

      request.headers['X-Last-Fetched-At'] = microseconds(last_fetched_at)

      expect(NotesFinder).to receive(:new)
        .with(anything, hash_including(last_fetched_at: last_fetched_at))
        .and_call_original

      expect(ResourceEvents::MergeIntoNotesService).to receive(:new)
        .with(anything, anything, hash_including(last_fetched_at: last_fetched_at))
        .and_call_original

      get :index, params: request_params
    end

    context 'when user notes_filter is present' do
      let(:notes_json) { parsed_response[:notes] }
      let!(:comment) { create(:note, noteable: issue, project: project) }
      let!(:system_note) { create(:note, noteable: issue, project: project, system: true) }

      it 'filters system notes by comments' do
        user.set_notes_filter(UserPreference::NOTES_FILTERS[:only_comments], issue)

        get :index, params: request_params

        expect(notes_json.count).to eq(1)
        expect(notes_json.first[:id].to_i).to eq(comment.id)
      end

      it 'returns all notes' do
        user.set_notes_filter(UserPreference::NOTES_FILTERS[:all_notes], issue)

        get :index, params: request_params

        expect(notes_json.map { |note| note[:id].to_i }).to contain_exactly(comment.id, system_note.id)
      end

      it 'does not merge label event notes' do
        user.set_notes_filter(UserPreference::NOTES_FILTERS[:only_comments], issue)

        expect(ResourceEvents::MergeIntoNotesService).not_to receive(:new)

        get :index, params: request_params
      end
    end

    context 'for multiple pages of notes', :aggregate_failures do
      # 3 pages worth: 1 normal page, 1 oversized due to clashing updated_at,
      # and a final, short page
      let!(:page_1) { create_list(:note, 2, noteable: issue, project: project, updated_at: 3.days.ago) }
      let!(:page_2) { create_list(:note, 3, noteable: issue, project: project, updated_at: 2.days.ago) }
      let!(:page_3) { create_list(:note, 2, noteable: issue, project: project, updated_at: 1.day.ago) }

      # Include a resource event in the middle page as well
      let!(:resource_event) { create(:resource_state_event, issue: issue, user: user, created_at: 2.days.ago) }

      let(:page_1_boundary) { microseconds(page_1.last.updated_at + NotesFinder::FETCH_OVERLAP) }
      let(:page_2_boundary) { microseconds(page_2.last.updated_at + NotesFinder::FETCH_OVERLAP) }

      around do |example|
        freeze_time do
          example.run
        end
      end

      before do
        stub_const('Gitlab::UpdatedNotesPaginator::LIMIT', 2)
      end

      context 'feature flag enabled' do
        before do
          stub_feature_flags(paginated_notes: true)
        end

        it 'returns the first page of notes' do
          expect(Gitlab::EtagCaching::Middleware).to receive(:skip!)

          get :index, params: request_params

          expect(json_response['notes'].count).to eq(page_1.count)
          expect(json_response['more']).to be_truthy
          expect(json_response['last_fetched_at']).to eq(page_1_boundary)
          expect(response.headers['Poll-Interval'].to_i).to eq(1)
        end

        it 'returns the second page of notes' do
          expect(Gitlab::EtagCaching::Middleware).to receive(:skip!)

          request.headers['X-Last-Fetched-At'] = page_1_boundary

          get :index, params: request_params

          expect(json_response['notes'].count).to eq(page_2.count + 1) # resource event
          expect(json_response['more']).to be_truthy
          expect(json_response['last_fetched_at']).to eq(page_2_boundary)
          expect(response.headers['Poll-Interval'].to_i).to eq(1)
        end

        it 'returns the final page of notes' do
          expect(Gitlab::EtagCaching::Middleware).to receive(:skip!)

          request.headers['X-Last-Fetched-At'] = page_2_boundary

          get :index, params: request_params

          expect(json_response['notes'].count).to eq(page_3.count)
          expect(json_response['more']).to be_falsy
          expect(json_response['last_fetched_at']).to eq(microseconds(Time.zone.now))
          expect(response.headers['Poll-Interval'].to_i).to be > 1
        end

        it 'returns an empty page of notes' do
          expect(Gitlab::EtagCaching::Middleware).not_to receive(:skip!)

          request.headers['X-Last-Fetched-At'] = microseconds(Time.zone.now)

          get :index, params: request_params

          expect(json_response['notes']).to be_empty
          expect(json_response['more']).to be_falsy
          expect(json_response['last_fetched_at']).to eq(microseconds(Time.zone.now))
          expect(response.headers['Poll-Interval'].to_i).to be > 1
        end
      end

      context 'feature flag disabled' do
        before do
          stub_feature_flags(paginated_notes: false)
        end

        it 'returns all notes' do
          get :index, params: request_params

          expect(json_response['notes'].count).to eq((page_1 + page_2 + page_3).size + 1)
          expect(json_response['more']).to be_falsy
          expect(json_response['last_fetched_at']).to eq(microseconds(Time.zone.now))
        end
      end
    end

    context 'for a discussion note' do
      let(:project) { create(:project, :repository) }
      let!(:note) { create(:discussion_note_on_merge_request, project: project) }

      let(:params) { request_params.merge(target_type: 'merge_request', target_id: note.noteable_id, html: true) }

      it 'responds with the expected attributes' do
        get :index, params: params

        expect(note_json[:id]).to eq(note.id)
        expect(note_json[:discussion_html]).not_to be_nil
        expect(note_json[:diff_discussion_html]).to be_nil
        expect(note_json[:discussion_line_code]).to be_nil
      end
    end

    context 'for a diff discussion note' do
      let(:project) { create(:project, :repository) }
      let!(:note) { create(:diff_note_on_merge_request, project: project) }

      let(:params) { request_params.merge(target_type: 'merge_request', target_id: note.noteable_id, html: true) }

      it 'responds with the expected attributes' do
        get :index, params: params

        expect(note_json[:id]).to eq(note.id)
        expect(note_json[:discussion_html]).not_to be_nil
        expect(note_json[:diff_discussion_html]).not_to be_nil
        expect(note_json[:discussion_line_code]).not_to be_nil
      end
    end

    context 'for a commit note' do
      let(:project) { create(:project, :repository) }
      let!(:note) { create(:note_on_commit, project: project) }

      context 'when displayed on a merge request' do
        let(:merge_request) { create(:merge_request, source_project: project) }

        let(:params) { request_params.merge(target_type: 'merge_request', target_id: merge_request.id, html: true) }

        it 'responds with the expected attributes' do
          get :index, params: params

          expect(note_json[:id]).to eq(note.id)
          expect(note_json[:discussion_html]).not_to be_nil
          expect(note_json[:diff_discussion_html]).to be_nil
          expect(note_json[:discussion_line_code]).to be_nil
        end
      end

      context 'when displayed on the commit' do
        let(:params) { request_params.merge(target_type: 'commit', target_id: note.commit_id, html: true) }

        it 'responds with the expected attributes' do
          get :index, params: params

          expect(note_json[:id]).to eq(note.id)
          expect(note_json[:discussion_html]).to be_nil
          expect(note_json[:diff_discussion_html]).to be_nil
          expect(note_json[:discussion_line_code]).to be_nil
        end

        context 'when user cannot read commit' do
          before do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user, :download_code, project).and_return(false)
          end

          it 'renders 404' do
            get :index, params: params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'for a regular note' do
      let!(:note) { create(:note_on_merge_request, project: project) }

      let(:params) { request_params.merge(target_type: 'merge_request', target_id: note.noteable_id, html: true) }

      it 'responds with the expected attributes' do
        get :index, params: params

        expect(note_json[:id]).to eq(note.id)
        expect(note_json[:html]).not_to be_nil
        expect(note_json[:discussion_html]).to be_nil
        expect(note_json[:diff_discussion_html]).to be_nil
        expect(note_json[:discussion_line_code]).to be_nil
      end
    end

    context 'with cross-reference system note', :request_store do
      let(:new_issue) { create(:issue) }
      let(:cross_reference) { "mentioned in #{new_issue.to_reference(issue.project)}" }

      before do
        note
        create(:discussion_note_on_issue, :system, noteable: issue, project: issue.project, note: cross_reference)
      end

      it 'filters notes that the user should not see' do
        get :index, params: request_params

        expect(parsed_response[:notes].count).to eq(1)
        expect(note_json[:id]).to eq(note.id.to_s)
      end

      it 'does not result in N+1 queries' do
        # Instantiate the controller variables to ensure QueryRecorder has an accurate base count
        get :index, params: request_params

        RequestStore.clear!

        control_count = ActiveRecord::QueryRecorder.new do
          get :index, params: request_params
        end.count

        RequestStore.clear!

        create_list(:discussion_note_on_issue, 2, :system, noteable: issue, project: issue.project, note: cross_reference)

        expect { get :index, params: request_params }.not_to exceed_query_limit(control_count)
      end
    end
  end

  describe 'POST create' do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.source_project }
    let(:note_text) { 'some note' }
    let(:request_params) do
      {
        note: { note: note_text, noteable_id: merge_request.id, noteable_type: 'MergeRequest' }.merge(extra_note_params),
        namespace_id: project.namespace,
        project_id: project,
        merge_request_diff_head_sha: 'sha',
        target_type: 'merge_request',
        target_id: merge_request.id
      }.merge(extra_request_params)
    end

    let(:extra_request_params) { {} }
    let(:extra_note_params) { {} }

    let(:project_visibility) { Gitlab::VisibilityLevel::PUBLIC }
    let(:merge_requests_access_level) { ProjectFeature::ENABLED }

    def create!
      post :create, params: request_params
    end

    before do
      project.update_attribute(:visibility_level, project_visibility)
      project.project_feature.update!(merge_requests_access_level: merge_requests_access_level)
      sign_in(user)
    end

    describe 'making the creation request' do
      before do
        create!
      end

      context 'the project is publically available' do
        context 'for HTML' do
          it "returns status 302" do
            expect(response).to have_gitlab_http_status(:found)
          end
        end

        context 'for JSON' do
          let(:extra_request_params) { { format: :json } }

          it "returns status 200 for json" do
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'the note does not have commands_only errors' do
        context 'for empty note' do
          let(:note_text) { '' }
          let(:extra_request_params) { { format: :json } }

          it "returns status 422 for json" do
            expect(response).to have_gitlab_http_status(:unprocessable_entity)
          end
        end
      end

      context 'the project is a private project' do
        let(:project_visibility) { Gitlab::VisibilityLevel::PRIVATE }

        [{}, { format: :json }].each do |extra|
          context "format is #{extra[:format]}" do
            let(:extra_request_params) { extra }

            it "returns status 404" do
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end
      end
    end

    context 'the user is a developer on a private project' do
      let(:project_visibility) { Gitlab::VisibilityLevel::PRIVATE }

      before do
        project.add_developer(user)
      end

      context 'HTML requests' do
        it "returns status 302 (redirect)" do
          create!

          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'JSON requests' do
        let(:extra_request_params) { { format: :json } }

        it "returns status 200" do
          create!

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'the return_discussion param is set' do
        let(:extra_request_params) { { format: :json, return_discussion: 'true' } }

        it 'returns discussion JSON when the return_discussion param is set' do
          create!

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to have_key 'discussion'
          expect(json_response.dig('discussion', 'notes', 0, 'note')).to eq(request_params[:note][:note])
        end
      end

      context 'when creating a confidential note' do
        let(:extra_request_params) { { format: :json } }

        context 'when `confidential` parameter is not provided' do
          it 'sets `confidential` to `false` in JSON response' do
            create!

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['confidential']).to be false
          end
        end

        context 'when `confidential` parameter is `false`' do
          let(:extra_note_params) { { confidential: false } }

          it 'sets `confidential` to `false` in JSON response' do
            create!

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['confidential']).to be false
          end
        end

        context 'when `confidential` parameter is `true`' do
          let(:extra_note_params) { { confidential: true } }

          it 'sets `confidential` to `true` in JSON response' do
            create!

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['confidential']).to be true
          end
        end
      end

      context 'when creating a note with quick actions' do
        context 'with commands that return changes' do
          let(:note_text) { "/award :thumbsup:\n/estimate 1d\n/spend 3h" }
          let(:extra_request_params) { { format: :json } }

          it 'includes changes in commands_changes' do
            create!

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['commands_changes']).to include('emoji_award', 'time_estimate', 'spend_time')
            expect(json_response['commands_changes']).not_to include('target_project', 'title')
          end
        end

        context 'with commands that do not return changes' do
          let(:issue) { create(:issue, project: project) }
          let(:other_project) { create(:project) }
          let(:note_text) { "/move #{other_project.full_path}\n/title AAA" }
          let(:extra_request_params) { { format: :json, target_id: issue.id, target_type: 'issue' } }

          before do
            other_project.add_developer(user)
          end

          it 'does not include changes in commands_changes' do
            create!

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['commands_changes']).not_to include('target_project', 'title')
          end
        end
      end
    end

    context 'when the internal project prohibits non-members from accessing merge requests' do
      let(:project_visibility) { Gitlab::VisibilityLevel::INTERNAL }
      let(:merge_requests_access_level) { ProjectFeature::PRIVATE }

      it "prevents a non-member user from creating a note on one of the project's merge requests" do
        create!

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when the user is a team member' do
        before do
          project.add_developer(user)
        end

        it 'can add comments' do
          expect { create! }.to change { project.notes.count }.by(1)
        end
      end

      # Illustration of the attack vector for posting comments to discussions that should
      # be inaccessible.
      #
      # This relies on posting a note to a commit that is not necessarily even in the
      # merge request, with a value of :in_reply_to_discussion_id that points to a
      # discussion on a merge_request that should not be accessible.
      context 'when the request includes a :in_reply_to_discussion_id designed to fool us' do
        let(:commit) { create(:commit, project: project) }

        let(:existing_comment) do
          create(:note_on_commit,
                 note: 'first',
                 project: project,
                 commit_id: merge_request.commit_shas.first)
        end

        let(:discussion) { existing_comment.discussion }

        # see !60465 for details of the structure of this request
        let(:request_params) do
          { "utf8" => "✓",
            "authenticity_token" => "1",
            "view" => "inline",
            "line_type" => "",
            "merge_request_diff_head_sha" => "",
            "in_reply_to_discussion_id" => discussion.id,
            "note_project_id" => project.id,
            "project_id" => project.id,
            "namespace_id" => project.namespace,
            "target_type" => "commit",
            "target_id" => commit.id,
            "note" => {
              "noteable_type" => "",
              "noteable_id" => "",
              "commit_id" => "",
              "type" => "",
              "line_code" => "",
              "position" => "",
              "note" => "ThisReplyWillGoToMergeRequest"
            } }
        end

        it 'prevents the request from adding notes to the spoofed discussion' do
          expect { create! }.not_to change { discussion.notes.count }
        end

        it 'returns an error to the user' do
          create!
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when the public project prohibits non-members from accessing merge requests' do
      let(:project_visibility) { Gitlab::VisibilityLevel::PUBLIC }
      let(:merge_requests_access_level) { ProjectFeature::PRIVATE }

      it "prevents a non-member user from creating a note on one of the project's merge requests" do
        create!

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when the user is a team member' do
        before do
          project.add_developer(user)
          create!
        end

        it 'can add comments' do
          expect(response).to be_redirect
        end
      end
    end

    context 'when merge_request_diff_head_sha present' do
      before do
        service_params = ActionController::Parameters.new({
          note: 'some note',
          noteable_id: merge_request.id,
          noteable_type: 'MergeRequest',
          commit_id: nil,
          merge_request_diff_head_sha: 'sha'
        }).permit!

        expect(Notes::CreateService).to receive(:new).with(project, user, service_params).and_return(double(execute: true))
      end

      it "returns status 302 for html" do
        create!

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when creating a comment on a commit with SHA1 starting with a large number' do
      let(:commit) { create(:commit, project: project, id: '842616594688d2351480dfebd67b3d8d15571e6d') }

      it 'creates a note successfully' do
        expect do
          post :create, params: {
            note: { note: 'some note', commit_id: commit.id },
            namespace_id: project.namespace,
            project_id: project,
            target_type: 'commit',
            target_id: commit.id
          }
        end.to change { Note.count }.by(1)
      end
    end

    context 'when creating a commit comment from an MR fork' do
      let(:project) { create(:project, :repository, :public) }

      let(:forked_project) do
        fork_project(project, nil, repository: true)
      end

      let(:merge_request) do
        create(:merge_request, source_project: forked_project, target_project: project, source_branch: 'feature', target_branch: 'master')
      end

      let(:existing_comment) do
        create(:note_on_commit, note: 'a note', project: forked_project, commit_id: merge_request.commit_shas.first)
      end

      let(:note_project_id) do
        forked_project.id
      end

      let(:request_params) do
        {
          note: { note: 'some other note', noteable_id: merge_request.id },
          namespace_id: project.namespace,
          project_id: project,
          target_type: 'merge_request',
          target_id: merge_request.id,
          note_project_id: note_project_id,
          in_reply_to_discussion_id: existing_comment.discussion_id
        }
      end

      let(:fork_visibility) { Gitlab::VisibilityLevel::PUBLIC }

      before do
        forked_project.update_attribute(:visibility_level, fork_visibility)
      end

      context 'when the note_project_id is not correct' do
        let(:note_project_id) do
          project.id && Project.maximum(:id).succ
        end

        it 'returns a 404', :sidekiq_might_not_need_inline do
          create!
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the user has no access to the fork' do
        let(:fork_visibility) { Gitlab::VisibilityLevel::PRIVATE }

        it 'returns a 404', :sidekiq_might_not_need_inline do
          create!
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the user has access to the fork', :sidekiq_might_not_need_inline do
        let!(:discussion) { forked_project.notes.find_discussion(existing_comment.discussion_id) }
        let(:fork_visibility) { Gitlab::VisibilityLevel::PUBLIC }

        it 'is successful' do
          create!
          expect(response).to have_gitlab_http_status(:found)
        end

        it 'creates the note' do
          expect { create! }.to change { forked_project.notes.count }.by(1)
        end
      end
    end

    context 'when target_id and noteable_id do not match' do
      let(:locked_issue) { create(:issue, :locked, project: project) }
      let(:issue) {create(:issue, project: project)}

      it 'uses target_id and ignores noteable_id' do
        request_params = {
          note: { note: 'some note', noteable_type: 'Issue', noteable_id: locked_issue.id },
          target_type: 'issue',
          target_id: issue.id,
          project_id: project,
          namespace_id: project.namespace
        }

        expect { post :create, params: request_params }.to change { issue.notes.count }.by(1)
          .and change { locked_issue.notes.count }.by(0)
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when the merge request discussion is locked' do
      before do
        merge_request.update_attribute(:discussion_locked, true)
      end

      context 'when a noteable is not found' do
        it 'returns 404 status' do
          request_params[:target_id] = non_existing_record_id
          post :create, params: request_params.merge(format: :json)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when a user is a team member' do
        before do
          project.add_developer(user)
        end

        it 'returns 302 status for html' do
          post :create, params: request_params

          expect(response).to have_gitlab_http_status(:found)
        end

        it 'returns 200 status for json' do
          post :create, params: request_params.merge(format: :json)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'creates a new note' do
          expect { post :create, params: request_params }.to change { Note.count }.by(1)
        end
      end

      context 'when a user is not a team member' do
        it 'returns 404 status' do
          post :create, params: request_params

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'does not create a new note' do
          expect { post :create, params: request_params }.not_to change { Note.count }
        end
      end
    end

    it_behaves_like 'request exceeding rate limit', :clean_gitlab_redis_cache do
      let(:params) { request_params.except(:format) }
      let(:request_full_path) { project_notes_path(project) }
    end
  end

  describe 'PUT update' do
    context "should update the note with a valid issue" do
      let(:request_params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: note,
          format: :json,
          note: {
            note: "New comment"
          }
        }
      end

      before do
        sign_in(note.author)
        project.add_developer(note.author)
      end

      it "updates the note" do
        expect { put :update, params: request_params }.to change { note.reload.note }
      end
    end
    context "doesnt update the note" do
      let(:issue)   { create(:issue, :confidential, project: project) }
      let(:note)    { create(:note, noteable: issue, project: project) }

      before do
        sign_in(user)
        project.add_guest(user)
      end

      it "disallows edits when the issue is confidential and the user has guest permissions" do
        request_params = {
          namespace_id: project.namespace,
          project_id: project,
          id: note,
          format: :json,
          note: {
            note: "New comment"
          }
        }
        expect { put :update, params: request_params }.not_to change { note.reload.note }
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE destroy' do
    let(:request_params) do
      {
          namespace_id: project.namespace,
          project_id: project,
          id: note,
          format: :js
      }
    end

    context 'user is the author of a note' do
      before do
        sign_in(note.author)
        project.add_developer(note.author)
      end

      it "returns status 200 for html" do
        delete :destroy, params: request_params

        expect(response).to have_gitlab_http_status(:ok)
      end

      it "deletes the note" do
        expect { delete :destroy, params: request_params }.to change { Note.count }.from(1).to(0)
      end
    end

    context 'user is not the author of a note' do
      before do
        sign_in(user)
        project.add_developer(user)
      end

      it "returns status 404" do
        delete :destroy, params: request_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST toggle_award_emoji' do
    before do
      sign_in(user)
      project.add_developer(user)
    end

    subject { post(:toggle_award_emoji, params: request_params.merge(name: emoji_name)) }

    let(:emoji_name) { 'thumbsup' }

    it "toggles the award emoji" do
      expect do
        subject
      end.to change { note.award_emoji.count }.by(1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it "removes the already awarded emoji" do
      create(:award_emoji, awardable: note, name: emoji_name, user: user)

      expect { subject }.to change { AwardEmoji.count }.by(-1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'marks Todos on the Noteable as done' do
      todo = create(:todo, target: note.noteable, project: project, user: user)

      subject

      expect(todo.reload).to be_done
    end
  end

  describe "resolving and unresolving" do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }

    describe 'POST resolve' do
      before do
        sign_in user
      end

      context "when the user is not authorized to resolve the note" do
        it "returns status 404" do
          post :resolve, params: request_params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when the user is authorized to resolve the note" do
        before do
          project.add_developer(user)
        end

        context "when the note is not resolvable" do
          before do
            note.update!(system: true)
          end

          it "returns status 404" do
            post :resolve, params: request_params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context "when the note is resolvable" do
          it "resolves the note" do
            post :resolve, params: request_params

            expect(note.reload.resolved?).to be true
            expect(note.reload.resolved_by).to eq(user)
          end

          it "sends notifications if all discussions are resolved" do
            expect_next_instance_of(MergeRequests::ResolvedDiscussionNotificationService) do |instance|
              expect(instance).to receive(:execute).with(merge_request)
            end

            post :resolve, params: request_params
          end

          it "returns the name of the resolving user" do
            post :resolve, params: request_params.merge(html: true)

            expect(json_response["resolved_by"]).to eq(user.name)
          end

          it "returns status 200" do
            post :resolve, params: request_params

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    describe 'DELETE unresolve' do
      before do
        sign_in user

        note.resolve!(user)
      end

      context "when the user is not authorized to resolve the note" do
        it "returns status 404" do
          delete :unresolve, params: request_params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when the user is authorized to resolve the note" do
        before do
          project.add_developer(user)
        end

        context "when the note is not resolvable" do
          before do
            note.update!(system: true)
          end

          it "returns status 404" do
            delete :unresolve, params: request_params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context "when the note is resolvable" do
          it "unresolves the note" do
            delete :unresolve, params: request_params

            expect(note.reload.resolved?).to be false
          end

          it "returns status 200" do
            delete :unresolve, params: request_params

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end

  # Convert a time to an integer number of microseconds
  def microseconds(time)
    (time.to_i * 1_000_000) + time.usec
  end
end
