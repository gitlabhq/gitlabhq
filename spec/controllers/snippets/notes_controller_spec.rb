require 'spec_helper'

describe Snippets::NotesController do
  let(:user) { create(:user) }

  let(:private_snippet)  { create(:personal_snippet, :private) }
  let(:internal_snippet) { create(:personal_snippet, :internal) }
  let(:public_snippet)   { create(:personal_snippet, :public) }

  let(:note_on_private)  { create(:note_on_personal_snippet, noteable: private_snippet) }
  let(:note_on_internal) { create(:note_on_personal_snippet, noteable: internal_snippet) }
  let(:note_on_public)   { create(:note_on_personal_snippet, noteable: public_snippet) }

  describe 'GET index' do
    context 'when a snippet is public' do
      before do
        note_on_public

        get :index, { snippet_id: public_snippet }
      end

      it "returns status 200" do
        expect(response).to have_gitlab_http_status(200)
      end

      it "returns not empty array of notes" do
        expect(JSON.parse(response.body)["notes"].empty?).to be_falsey
      end
    end

    context 'when a snippet is internal' do
      before do
        note_on_internal
      end

      context 'when user not logged in' do
        it "returns status 404" do
          get :index, { snippet_id: internal_snippet }

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when user logged in' do
        before do
          sign_in(user)
        end

        it "returns status 200" do
          get :index, { snippet_id: internal_snippet }

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end

    context 'when a snippet is private' do
      before do
        note_on_private
      end

      context 'when user not logged in' do
        it "returns status 404" do
          get :index, { snippet_id: private_snippet }

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when user other than author logged in' do
        before do
          sign_in(user)
        end

        it "returns status 404" do
          get :index, { snippet_id: private_snippet }

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when author logged in' do
        before do
          note_on_private

          sign_in(private_snippet.author)
        end

        it "returns status 200" do
          get :index, { snippet_id: private_snippet }

          expect(response).to have_gitlab_http_status(200)
        end

        it "returns 1 note" do
          get :index, { snippet_id: private_snippet }

          expect(JSON.parse(response.body)['notes'].count).to eq(1)
        end
      end
    end

    context 'dont show non visible notes' do
      before do
        note_on_public

        sign_in(user)

        expect_any_instance_of(Note).to receive(:cross_reference_not_visible_for?).and_return(true)
      end

      it "does not return any note" do
        get :index, { snippet_id: public_snippet }

        expect(JSON.parse(response.body)['notes'].count).to eq(0)
      end
    end
  end

  describe 'DELETE destroy' do
    let(:request_params) do
      {
        snippet_id: public_snippet,
        id: note_on_public,
        format: :js
      }
    end

    context 'when user is the author of a note' do
      before do
        sign_in(note_on_public.author)
      end

      it "returns status 200" do
        delete :destroy, request_params

        expect(response).to have_gitlab_http_status(200)
      end

      it "deletes the note" do
        expect { delete :destroy, request_params }.to change { Note.count }.from(1).to(0)
      end

      context 'system note' do
        before do
          expect_any_instance_of(Note).to receive(:system?).and_return(true)
        end

        it "does not delete the note" do
          expect { delete :destroy, request_params }.not_to change { Note.count }
        end
      end
    end

    context 'when user is not the author of a note' do
      before do
        sign_in(user)

        note_on_public
      end

      it "returns status 404" do
        delete :destroy, request_params

        expect(response).to have_gitlab_http_status(404)
      end

      it "does not update the note" do
        expect { delete :destroy, request_params }.not_to change { Note.count }
      end
    end
  end

  describe 'POST toggle_award_emoji' do
    let(:note) { create(:note_on_personal_snippet, noteable: public_snippet) }
    before do
      sign_in(user)
    end

    subject { post(:toggle_award_emoji, snippet_id: public_snippet, id: note.id, name: "thumbsup") }

    it "toggles the award emoji" do
      expect { subject }.to change { note.award_emoji.count }.by(1)

      expect(response).to have_gitlab_http_status(200)
    end

    it "removes the already awarded emoji when it exists" do
      note.toggle_award_emoji('thumbsup', user) # create award emoji before

      expect { subject }.to change { AwardEmoji.count }.by(-1)

      expect(response).to have_gitlab_http_status(200)
    end
  end
end
