# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Snippets > User updates a snippet', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let_it_be(:snippet, reload: true) { create(:project_snippet, :repository, project: project, author: user) }

  before do
    stub_feature_flags(snippets_vue: false)
    stub_feature_flags(snippets_edit_vue: false)

    project.add_maintainer(user)
    sign_in(user)

    visit(project_snippet_path(project, snippet))

    page.within('.detail-page-header') do
      first(:link, 'Edit').click
    end
    wait_for_all_requests
  end

  it 'displays the snippet blob path and content' do
    blob = snippet.blobs.first

    aggregate_failures do
      expect(page.find_field('project_snippet_file_name').value).to eq blob.path
      expect(page.find('.file-content')).to have_content(blob.data.strip)
      expect(page.find('.snippet-file-content', visible: false).value).to eq blob.data
    end
  end

  it 'updates a snippet' do
    fill_in('project_snippet_title', with: 'Snippet new title')
    click_button('Save')

    expect(page).to have_content('Snippet new title')
  end

  context 'when the git operation fails' do
    before do
      allow_next_instance_of(Snippets::UpdateService) do |instance|
        allow(instance).to receive(:create_commit).and_raise(StandardError, 'Error Message')
      end

      fill_in('project_snippet_title', with: 'Snippet new title')
      fill_in('project_snippet_file_name', with: 'new_file_name')

      click_button('Save')
    end

    it 'renders edit page and displays the error' do
      expect(page.find('.flash-container span').text).to eq('Error updating the snippet - Error Message')
      expect(page).to have_content('Edit Snippet')
    end
  end
end
