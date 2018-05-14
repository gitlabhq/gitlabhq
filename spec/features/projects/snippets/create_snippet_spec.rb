require 'rails_helper'

describe 'Projects > Snippets > Create Snippet', :js do
  include DropzoneHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  def fill_form
    fill_in 'project_snippet_title', with: 'My Snippet Title'
    fill_in 'project_snippet_description', with: 'My Snippet **Description**'
    page.within('.file-editor') do
      find('.ace_text-input', visible: false).send_keys('Hello World!')
    end
  end

  context 'when a user is authenticated' do
    before do
      project.add_master(user)
      sign_in(user)

      visit project_snippets_path(project)

      click_on('New snippet')
    end

    it 'creates a new snippet' do
      fill_form
      click_button('Create snippet')
      wait_for_requests

      expect(page).to have_content('My Snippet Title')
      expect(page).to have_content('Hello World!')
      page.within('.snippet-header .description') do
        expect(page).to have_content('My Snippet Description')
        expect(page).to have_selector('strong')
      end
    end

    it 'uploads a file when dragging into textarea' do
      fill_form
      dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

      expect(page.find_field("project_snippet_description").value).to have_content('banana_sample')

      click_button('Create snippet')
      wait_for_requests

      link = find('a.no-attachment-icon img[alt="banana_sample"]')['src']
      expect(link).to match(%r{/#{Regexp.escape(project.full_path) }/uploads/\h{32}/banana_sample\.gif\z})
    end

    it 'creates a snippet when all reuiqred fields are filled in after validation failing' do
      fill_in 'project_snippet_title', with: 'My Snippet Title'
      click_button('Create snippet')

      expect(page).to have_selector('#error_explanation')

      fill_form
      dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

      find("input[value='Create snippet']").send_keys(:return)
      wait_for_requests

      expect(page).to have_content('My Snippet Title')
      expect(page).to have_content('Hello World!')
      page.within('.snippet-header .description') do
        expect(page).to have_content('My Snippet Description')
        expect(page).to have_selector('strong')
      end
      link = find('a.no-attachment-icon img[alt="banana_sample"]')['src']
      expect(link).to match(%r{/#{Regexp.escape(project.full_path) }/uploads/\h{32}/banana_sample\.gif\z})
    end
  end

  context 'when a user is not authenticated' do
    it 'shows a public snippet on the index page but not the New snippet button' do
      snippet = create(:project_snippet, :public, project: project)

      visit project_snippets_path(project)

      expect(page).to have_content(snippet.title)
      expect(page).not_to have_content('New snippet')
    end
  end
end
