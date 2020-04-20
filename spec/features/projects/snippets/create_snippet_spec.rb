# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'snippet editor' do
  before do
    stub_feature_flags(snippets_edit_vue: false)
    stub_feature_flags(monaco_snippets: flag)
  end

  def description_field
    find('.js-description-input').find('input,textarea')
  end

  def fill_form
    fill_in 'project_snippet_title', with: 'My Snippet Title'

    # Click placeholder first to expand full description field
    description_field.click
    fill_in 'project_snippet_description', with: 'My Snippet **Description**'

    page.within('.file-editor') do
      el = flag == true ? find('.inputarea') : find('.ace_text-input', visible: false)
      el.send_keys 'Hello World!'
    end
  end

  context 'when a user is authenticated' do
    before do
      stub_feature_flags(snippets_vue: false)
      project.add_maintainer(user)
      sign_in(user)

      visit project_snippets_path(project)

      # Wait for the SVG to ensure the button location doesn't shift
      within('.empty-state') { find('img.js-lazy-loaded') }
      click_on('New snippet')
      wait_for_requests
    end

    it 'shows collapsible description input' do
      collapsed = description_field

      expect(page).not_to have_field('project_snippet_description')
      expect(collapsed).to be_visible

      collapsed.click

      expect(page).to have_field('project_snippet_description')
      expect(collapsed).not_to be_visible
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
      expect(link).to match(%r{/#{Regexp.escape(project.full_path)}/uploads/\h{32}/banana_sample\.gif\z})
    end

    it 'creates a snippet when all required fields are filled in after validation failing' do
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
      expect(link).to match(%r{/#{Regexp.escape(project.full_path)}/uploads/\h{32}/banana_sample\.gif\z})
    end

    context 'when the git operation fails' do
      let(:error) { 'This is a git error' }

      before do
        allow_next_instance_of(Snippets::CreateService) do |instance|
          allow(instance).to receive(:create_commit).and_raise(StandardError, error)
        end

        fill_form

        click_button('Create snippet')
        wait_for_requests
      end

      it 'displays the error' do
        expect(page).to have_content(error)
      end

      it 'renders new page' do
        expect(page).to have_content('New Snippet')
      end
    end
  end

  context 'when a user is not authenticated' do
    before do
      stub_feature_flags(snippets_vue: false)
    end

    it 'shows a public snippet on the index page but not the New snippet button' do
      snippet = create(:project_snippet, :public, :repository, project: project)

      visit project_snippets_path(project)

      expect(page).to have_content(snippet.title)
      expect(page).not_to have_content('New snippet')
    end
  end
end

describe 'Projects > Snippets > Create Snippet', :js do
  include DropzoneHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  context 'when using Monaco' do
    it_behaves_like "snippet editor" do
      let(:flag) { true }
    end
  end

  context 'when using ACE' do
    it_behaves_like "snippet editor" do
      let(:flag) { false }
    end
  end
end
