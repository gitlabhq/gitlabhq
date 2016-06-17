require('spec_helper')

describe Projects::NotesController do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:issue)   { create(:issue, project: project) }
  let(:note)    { create(:note, noteable: issue, project: project) }

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

      expect(response).to have_http_status(200)
    end

    it "removes the already awarded emoji" do
      post(:toggle_award_emoji, namespace_id: project.namespace.path,
                                project_id: project.path, id: note.id, name: "thumbsup")

      expect do
        post(:toggle_award_emoji, namespace_id: project.namespace.path,
                                  project_id: project.path, id: note.id, name: "thumbsup")
      end.to change { AwardEmoji.count }.by(-1)

      expect(response).to have_http_status(200)
    end
  end
end
