require 'spec_helper'

describe 'Projects > Wiki > User views Git access wiki page', :feature do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:wiki_page) do
    WikiPages::CreateService.new(
      project,
      user,
      title: 'home',
      content: '[some link](other-page)'
    ).execute
  end

  before do
    sign_in(user)
  end

  scenario 'Visit Wiki Page Current Commit' do
    visit project_wiki_path(project, wiki_page)

    click_link 'Clone repository'
    expect(page).to have_text("Clone repository #{project.wiki.path_with_namespace}")
    expect(page).to have_text(project.wiki.http_url_to_repo)
  end
end
