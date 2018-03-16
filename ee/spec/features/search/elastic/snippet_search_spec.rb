require 'spec_helper'

describe 'Snippet elastic search', :js, :elastic do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.add_master(user)
    sign_in(user)
  end

  describe 'searching' do
    it 'finds a personal snippet' do
      create(:personal_snippet, author: user, content: 'Test searching for personal snippets')

      visit explore_snippets_path
      fill_in 'search', with: 'Test'
      click_button 'Go'

      expect(page).to have_content('Test searching for personal snippets')
    end

    it 'finds a project snippet' do
      create(:project_snippet, project: project, content: 'Test searching for personal snippets')

      visit explore_snippets_path
      fill_in 'search', with: 'Test'
      click_button 'Go'

      expect(page).to have_content('Test searching for personal snippets')
    end
  end
end
