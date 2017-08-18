require 'spec_helper'

describe 'Reportable note on snippets', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe 'on project snippet' do
    let(:snippet) { create(:project_snippet, :public, project: project, author: user) }
    let!(:note) { create(:note_on_project_snippet, noteable: snippet, project: project) }

    before do
      visit project_snippet_path(project, snippet)
    end

    it_behaves_like 'reportable note', 'snippet'
  end
end
