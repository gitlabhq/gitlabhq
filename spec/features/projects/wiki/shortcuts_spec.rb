require 'spec_helper'

feature 'Wiki shortcuts', :js do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, namespace: user.namespace) }
  let(:wiki_page) do
    WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
  end

  before do
    sign_in(user)
    visit project_wiki_path(project, wiki_page)
  end

  scenario 'Visit edit wiki page using "e" keyboard shortcut' do
    find('body').native.send_key('e')

    expect(find('.wiki-page-title')).to have_content('Edit Page')
  end
end
