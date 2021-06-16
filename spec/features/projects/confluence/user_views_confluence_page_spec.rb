# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views the Confluence page' do
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project, :public) }

  before do
    sign_in(user)
  end

  it 'shows the page when the Confluence integration is enabled' do
    service = create(:confluence_integration, project: project)

    visit project_wikis_confluence_path(project)

    element = page.find('.row.empty-state')

    expect(element).to have_link('Go to Confluence', href: service.confluence_url)
  end

  it 'does not show the page when the Confluence integration disabled' do
    visit project_wikis_confluence_path(project)

    expect(page).to have_gitlab_http_status(:not_found)
  end
end
