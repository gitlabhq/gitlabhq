# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Snippets > Create Snippet', :js, feature_category: :source_code_management do
  include DropzoneHelper
  include Features::SnippetSpecHelpers

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

  def fill_form
    snippet_fill_in_form(title: title, content: file_content, description: md_description)
  end

  before do
    sign_in(user)

    visit new_project_snippet_path(project)
  end

  it 'creates a new snippet' do
    fill_form
    click_button('Create snippet')
    wait_for_requests

    expect(page).to have_content(title)
    expect(page).to have_content(file_content)
    within_testid('snippet-description') do
      expect(page).to have_content(description)
      expect(page).to have_selector('strong')
    end
  end

  it 'uploads a file when dragging into textarea' do
    fill_form
    dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

    expect(snippet_description_value).to have_content('banana_sample')

    click_button('Create snippet')
    wait_for_requests

    link = find('a.no-attachment-icon img.js-lazy-loaded[alt="banana_sample"]')['src']
    expect(link).to match(%r{/-/project/#{project.id}/uploads/\h{32}/banana_sample\.gif\z})
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
      expect(page).to have_content('New snippet')
    end
  end
end
