require 'spec_helper'

describe 'Reportable note on snippets', :feature, :js do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  before do
    project.add_master(user)
    login_as user
  end

  describe 'on project snippet' do
    let(:snippet) { create(:project_snippet, :public, project: project, author: user) }
    let!(:note) { create(:note_on_project_snippet, noteable: snippet, project: project) }

    before do
      visit namespace_project_snippet_path(project.namespace, project, snippet)
    end

    it_behaves_like 'reportable note'
  end

  describe 'on personal snippet' do
    let(:snippet) { create(:personal_snippet, :public, author: user) }
    let!(:note) { create(:note_on_personal_snippet, noteable: snippet, author: user) }

    before do
      visit snippet_path(snippet)
    end

    it_behaves_like 'reportable note'
  end
end
