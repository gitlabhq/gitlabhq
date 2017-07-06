require 'spec_helper'

feature 'Projects > Wiki > User views the wiki page', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:old_page_version_id) { wiki_page.versions.last.id }
  let(:wiki_page) do
    WikiPages::CreateService.new(
      project,
      user,
      title: 'home',
      content: '[some link](other-page)'
    ).execute
  end

  background do
    project.team << [user, :master]
    sign_in(user)
    WikiPages::UpdateService.new(
      project,
      user,
      message: 'updated home',
      content: 'updated [some link](other-page)',
      format: :markdown
    ).execute(wiki_page)
  end

  scenario 'Visit Wiki Page Current Commit' do
    visit project_wiki_path(project, wiki_page)

    expect(page).to have_selector('a.btn', text: 'Edit')
  end

  scenario 'Visit Wiki Page Historical Commit' do
    visit project_wiki_path(project, wiki_page, version_id: old_page_version_id)

    expect(page).not_to have_selector('a.btn', text: 'Edit')
  end
end
