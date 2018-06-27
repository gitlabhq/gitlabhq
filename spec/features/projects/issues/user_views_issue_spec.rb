require "spec_helper"

describe "User views issue" do
  set(:project) { create(:project_empty_repo, :public) }
  set(:user) { create(:user) }
  set(:issue) { create(:issue, project: project, description: "# Description header", author: user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  it { expect(page).to have_header_with_correct_id_and_link(1, "Description header", "description-header") }

  it 'shows the merge request and issue actions', :aggregate_failures do
    expect(page).to have_link('New issue')
    expect(page).to have_button('Create merge request')
    expect(page).to have_link('Close issue')
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
