# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views issue", feature_category: :team_planning do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:issue) { create(:issue, project: project, description: "# Description header\n\n**Lorem** _ipsum_ dolor sit [amet](https://example.com)", author: user) }
  let_it_be(:note) { create(:note, noteable: issue, project: project, author: user) }

  before do
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  it { expect(page).to have_header_with_correct_id_and_link(1, "Description header", "description-header") }

  it_behaves_like 'page meta description', ' Description header Lorem ipsum dolor sit amet'

  it 'shows the merge request and issue actions', :js, :aggregate_failures do
    click_button 'Issue actions'

    expect(page).to have_link('New related issue', href: new_project_issue_path(project, { add_related_issue: issue.iid }))
    expect(page).to have_button('Create merge request')
    expect(page).to have_button('Close issue')
  end

  context 'when the project is archived' do
    let(:project) { create(:project, :public, :archived) }

    it 'hides the merge request and issue actions', :aggregate_failures do
      expect(page).not_to have_link('New issue')
      expect(page).not_to have_button('Create merge request')
      expect(page).not_to have_link('Close issue')
    end
  end
end
