# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Snippets > User updates a snippet' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let!(:snippet) { create(:project_snippet, project: project, author: user) }

  before do
    stub_feature_flags(snippets_vue: false)
    project.add_maintainer(user)
    sign_in(user)

    visit(project_snippet_path(project, snippet))

    page.within('.detail-page-header') do
      first(:link, 'Edit').click
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
        allow(instance).to receive(:create_commit).and_raise(StandardError)
      end

      fill_in('project_snippet_title', with: 'Snippet new title')

      click_button('Save')
    end

    it 'renders edit page and displays the error' do
      expect(page.find('.flash-container span').text).to eq('Error updating the snippet')
      expect(page).to have_content('Edit Snippet')
    end
  end
end
