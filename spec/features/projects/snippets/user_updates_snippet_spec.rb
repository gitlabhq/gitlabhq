# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Snippets > User updates a snippet', :js, feature_category: :source_code_management do
  include Features::SnippetSpecHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let_it_be(:snippet, reload: true) { create(:project_snippet, :repository, project: project, author: user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    page.visit(edit_project_snippet_path(project, snippet))

    wait_for_all_requests
  end

  it 'displays the snippet blob path and content' do
    blob = snippet.blobs.first

    aggregate_failures do
      expect(snippet_get_first_blob_path).to eq blob.path
      expect(snippet_get_first_blob_value).to have_content(blob.data.strip)
    end
  end

  it 'updates a snippet' do
    fill_in('snippet-title', with: 'Snippet new title')
    click_button('Save')

    expect(page).to have_content('Snippet new title')
  end

  context 'when the git operation fails' do
    before do
      allow_next_instance_of(Snippets::UpdateService) do |instance|
        allow(instance).to receive(:create_commit).and_raise(StandardError, 'Error Message')
      end

      snippet_fill_in_form(title: 'Snippet new title', file_name: 'new_file_name')

      click_button('Save')
    end

    it 'renders edit page and displays the error' do
      expect(page.find('.flash-container')).to have_content('Error updating the snippet - Error Message')
      expect(page).to have_content('Edit snippet')
    end
  end
end
