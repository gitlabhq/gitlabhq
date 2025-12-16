# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views issue", :js, feature_category: :team_planning do
  context 'with a public project' do
    let_it_be(:project) { create(:project_empty_repo, :public) }
    let_it_be(:user) { create(:user, developer_of: project) }
    let_it_be(:issue) { create(:issue, project: project, description: "# Description header\n\n**Lorem** _ipsum_ dolor sit [amet](https://example.com)", author: user) }
    let_it_be(:note) { create(:note, noteable: issue, project: project, author: user) }

    before do
      sign_in(user)
      visit(project_issue_path(project, issue))
    end

    it { expect(page).to have_header_with_correct_id_and_link(1, "Description header", "description-header") }

    it_behaves_like 'page meta description', 'Description header  Lorem ipsum dolor sit amet'

    it 'shows the merge request and issue actions', :aggregate_failures do
      click_button 'More actions', match: :first

      expect(page).to have_button('New related item')
      expect(page).to have_button('Create merge request')
      expect(page).to have_button('Close issue')
    end
  end

  context 'when the project is archived' do
    let_it_be(:archived_project) { create(:project, :public, :archived) }
    let_it_be(:archived_user) { create(:user, developer_of: archived_project) }
    let_it_be(:archived_issue) { create(:issue, project: archived_project, author: archived_user) }

    before do
      sign_in(archived_user)
      visit(project_issue_path(archived_project, archived_issue))
    end

    it 'hides the merge request and issue actions', :aggregate_failures do
      click_button 'More actions', match: :first

      expect(page).not_to have_button('New related item')
      expect(page).not_to have_button('Create merge request')
      expect(page).not_to have_button('Close issue')
    end
  end
end
