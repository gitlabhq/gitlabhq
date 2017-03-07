require 'spec_helper'

describe SearchController do
  let(:user)    { create(:user) }

  before do
    sign_in(user)
  end

  it 'finds issue comments' do
    project = create(:empty_project, :public)
    note = create(:note_on_issue, project: project)

    get :show, project_id: project.id, scope: 'notes', search: note.note

    expect(assigns[:search_objects].first).to eq note
  end

  context 'on restricted projects' do
    context 'when signed out' do
      before { sign_out(user) }

      it "doesn't expose comments on issues" do
        project = create(:empty_project, :public, :issues_private)
        note = create(:note_on_issue, project: project)

        get :show, project_id: project.id, scope: 'notes', search: note.note

        expect(assigns[:search_objects].count).to eq(0)
      end
    end

    it "doesn't expose comments on merge_requests" do
      project = create(:empty_project, :public, :merge_requests_private)
      note = create(:note_on_merge_request, project: project)

      get :show, project_id: project.id, scope: 'notes', search: note.note

      expect(assigns[:search_objects].count).to eq(0)
    end

    it "doesn't expose comments on snippets" do
      project = create(:empty_project, :public, :snippets_private)
      note = create(:note_on_project_snippet, project: project)

      get :show, project_id: project.id, scope: 'notes', search: note.note

      expect(assigns[:search_objects].count).to eq(0)
    end
  end
end
