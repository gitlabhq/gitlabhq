require 'spec_helper'

describe Projects::NotesController do
  let(:user)    { create(:user) }
  let(:project) { create(:empty_project) }
  let(:issue)   { create(:issue, project: project) }
  let(:note)    { create(:note, noteable: issue, project: project) }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      id: note
    }
  end

  describe 'POST create' do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.source_project }
    let(:request_params) do
      {
        note: { note: 'some note', noteable_id: merge_request.id, noteable_type: 'MergeRequest' },
        namespace_id: project.namespace,
        project_id: project,
        merge_request_diff_head_sha: 'sha'
      }
    end

    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    it "returns status 302 for html" do
      post :create, request_params

      expect(response).to have_http_status(302)
    end

    it "returns status 200 for json" do
      post :create, request_params.merge(format: :json)

      expect(response).to have_http_status(200)
    end

    context 'when merge_request_diff_head_sha present' do
      before do
        service_params = {
          note: 'some note',
          noteable_id: merge_request.id.to_s,
          noteable_type: 'MergeRequest',
          merge_request_diff_head_sha: 'sha'
        }

        expect(Notes::CreateService).to receive(:new).with(project, user, service_params).and_return(double(execute: true))
      end

      it "returns status 302 for html" do
        post :create, request_params

        expect(response).to have_http_status(302)
      end
    end
  end

  describe 'POST toggle_award_emoji' do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    it "toggles the award emoji" do
      expect do
        post(:toggle_award_emoji, request_params.merge(name: "thumbsup"))
      end.to change { note.award_emoji.count }.by(1)

      expect(response).to have_http_status(200)
    end

    it "removes the already awarded emoji" do
      post(:toggle_award_emoji, request_params.merge(name: "thumbsup"))

      expect do
        post(:toggle_award_emoji, request_params.merge(name: "thumbsup"))
      end.to change { AwardEmoji.count }.by(-1)

      expect(response).to have_http_status(200)
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
          post :resolve, request_params

          expect(response).to have_http_status(404)
        end
      end

      context "when the user is authorized to resolve the note" do
        before do
          project.team << [user, :developer]
        end

        context "when the note is not resolvable" do
          before do
            note.update(system: true)
          end

          it "returns status 404" do
            post :resolve, request_params

            expect(response).to have_http_status(404)
          end
        end

        context "when the note is resolvable" do
          it "resolves the note" do
            post :resolve, request_params

            expect(note.reload.resolved?).to be true
            expect(note.reload.resolved_by).to eq(user)
          end

          it "sends notifications if all discussions are resolved" do
            expect_any_instance_of(MergeRequests::ResolvedDiscussionNotificationService).to receive(:execute).with(merge_request)

            post :resolve, request_params
          end

          it "returns the name of the resolving user" do
            post :resolve, request_params

            expect(JSON.parse(response.body)["resolved_by"]).to eq(user.name)
          end

          it "returns status 200" do
            post :resolve, request_params

            expect(response).to have_http_status(200)
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
          delete :unresolve, request_params

          expect(response).to have_http_status(404)
        end
      end

      context "when the user is authorized to resolve the note" do
        before do
          project.team << [user, :developer]
        end

        context "when the note is not resolvable" do
          before do
            note.update(system: true)
          end

          it "returns status 404" do
            delete :unresolve, request_params

            expect(response).to have_http_status(404)
          end
        end

        context "when the note is resolvable" do
          it "unresolves the note" do
            delete :unresolve, request_params

            expect(note.reload.resolved?).to be false
          end

          it "returns status 200" do
            delete :unresolve, request_params

            expect(response).to have_http_status(200)
          end
        end
      end
    end
  end
end
