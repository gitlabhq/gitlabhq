require 'spec_helper'

feature 'User deletes wiki page' do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:wiki_page) { create(:wiki_page, wiki: project.wiki) }

  before do
    sign_in(user)
    visit(project_wiki_path(project, wiki_page))
  end

  it 'deletes a page' do
    click_on('Edit')
    click_on('Delete')

    expect(page).to have_content('Page was successfully deleted')
  end
end
