# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Snippets > User updates a snippet' do
  let(:project) { create(:project) }
  let!(:snippet) { create(:project_snippet, project: project, author: user) }
  let(:user) { create(:user) }

  before do
    stub_feature_flags(snippets_vue: false)
    project.add_maintainer(user)
    sign_in(user)

    visit(project_snippet_path(project, snippet))
  end

  it 'updates a snippet' do
    page.within('.detail-page-header') do
      first(:link, 'Edit').click
    end

    fill_in('project_snippet_title', with: 'Snippet new title')
    click_button('Save')

    expect(page).to have_content('Snippet new title')
  end
end
