# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reportable note on snippets', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'on project snippet' do
    let_it_be_with_reload(:snippet) do
      create(:project_snippet, :public, :repository, project: project, author: user)
    end

    let_it_be_with_reload(:note) { create(:note_on_project_snippet, noteable: snippet, project: project) }

    before do
      visit project_snippet_path(project, snippet)
    end

    it_behaves_like 'reportable note', 'snippet'
  end
end
