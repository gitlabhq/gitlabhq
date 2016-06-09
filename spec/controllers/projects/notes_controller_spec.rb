require('spec_helper')

describe Projects::NotesController do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:issue)   { create(:issue, project: project) }
  let(:note)    { create(:note, noteable: issue, project: project, author: user) }

  describe 'POST #create' do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    context 'when creating notes is disabled' do
      it 'responds with a service unavailable error' do
        expect(Gitlab::Feature).to receive(:feature_enabled?).
          with(:creating_notes).
          and_return(false)

        post(:create,
            namespace_id: project.namespace.path,
            project_id: project.path)

        expect(response.status).to eq(503)
      end
    end
  end

  describe 'PUT #update' do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    context 'when updating notes is disabled' do
      it 'responds with a service unavailable error' do
        expect(Gitlab::Feature).to receive(:feature_enabled?).
          with(:updating_notes).
          and_return(false)

        put(:update,
           namespace_id: project.namespace.path,
           project_id: project.path,
           id: note.id)

        expect(response.status).to eq(503)
      end
    end
  end

  describe 'POST #toggle_award_emoji' do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    it "toggles the award emoji" do
      expect do
        post(:toggle_award_emoji, namespace_id: project.namespace.path,
                                  project_id: project.path, id: note.id, name: "thumbsup")
      end.to change { note.award_emoji.count }.by(1)

      expect(response.status).to eq(200)
    end

    it "removes the already awarded emoji" do
      post(:toggle_award_emoji, namespace_id: project.namespace.path,
                                project_id: project.path, id: note.id, name: "thumbsup")

      expect do
        post(:toggle_award_emoji, namespace_id: project.namespace.path,
                                  project_id: project.path, id: note.id, name: "thumbsup")
      end.to change { AwardEmoji.count }.by(-1)

      expect(response.status).to eq(200)
    end

    context 'when toggling award emoji is disabled' do
      it 'responds with a service unavailable error' do
        expect(Gitlab::Feature).to receive(:feature_enabled?).
          with(:toggling_award_emoji).
          and_return(false)

        post(:toggle_award_emoji, namespace_id: project.namespace.path,
                                  project_id: project.path, id: note.id, name: "thumbsup")

        expect(response.status).to eq(503)
      end
    end
  end
end
