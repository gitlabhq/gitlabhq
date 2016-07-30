require 'spec_helper'

describe Profiles::NoteTemplatesController do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    allow(subject).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let(:note_template) { create(:note_template) }

    it 'should list the note templates' do
      get :index

      expect(response).to be_success
    end
  end

  describe 'POST #create' do
    it 'should create a new note template' do
      expect do
        post :create, note_template: { title: 'Lorem ipsum dolor', note: 'Lorem ipsum dolor' }
      end.to change { user.note_templates.count }.by(1)

      expect(response).to redirect_to(profile_note_templates_path)
    end
  end
end
