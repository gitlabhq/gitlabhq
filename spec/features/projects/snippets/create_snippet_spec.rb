# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Snippets > Create Snippet', :js do
  include DropzoneHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) do
    create(:project, :public, creator: user).tap do |p|
      p.add_maintainer(user)
    end
  end

  let(:title) { 'My Snippet Title' }
  let(:file_content) { 'Hello World!' }
  let(:md_description) { 'My Snippet **Description**' }
  let(:description) { 'My Snippet Description' }

  before do
    stub_feature_flags(snippets_vue: false)
    stub_feature_flags(snippets_edit_vue: false)

    sign_in(user)

    visit new_project_snippet_path(project)
  end

  def description_field
    find('.js-description-input').find('input,textarea')
  end

  def fill_form
    fill_in 'project_snippet_title', with: title

    # Click placeholder first to expand full description field
    description_field.click
    fill_in 'project_snippet_description', with: md_description

    page.within('.file-editor') do
      el = find('.inputarea')
      el.send_keys file_content
    end
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

    expect(page).to have_content(title)
    expect(page).to have_content(file_content)
    page.within('.snippet-header .description') do
      expect(page).to have_content(description)
      expect(page).to have_selector('strong')
    end
  end

  it 'uploads a file when dragging into textarea' do
    fill_form
    dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

    expect(page.find_field('project_snippet_description').value).to have_content('banana_sample')

    click_button('Create snippet')
    wait_for_requests

    link = find('a.no-attachment-icon img[alt="banana_sample"]')['src']
    expect(link).to match(%r{/#{Regexp.escape(project.full_path)}/uploads/\h{32}/banana_sample\.gif\z})
  end

  it 'displays validation errors' do
    fill_in 'project_snippet_title', with: title
    click_button('Create snippet')
    wait_for_requests

    expect(page).to have_selector('#error_explanation')
  end

  context 'when the git operation fails' do
    let(:error) { 'Error creating the snippet' }

    before do
      allow_next_instance_of(Snippets::CreateService) do |instance|
        allow(instance).to receive(:create_commit).and_raise(StandardError, error)
      end

      fill_form

      click_button('Create snippet')
      wait_for_requests
    end

    it 'renders the new page and displays the error' do
      expect(page).to have_content(error)
      expect(page).to have_content('New Snippet')
    end
  end
end
