# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Snippets > User deletes a snippet', :js, feature_category: :source_code_management do
  include Spec::Support::Helpers::ModalHelpers

  let(:project) { create(:project) }
  let!(:snippet) { create(:project_snippet, project: project, author: user) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(project_snippet_path(project, snippet))
  end

  it 'deletes a snippet' do
    expect(page).to have_content(snippet.title)

    click_on 'Snippet actions'

    page.within(find_by_testid('snippets-more-actions-dropdown')) do
      click_on 'Delete'
    end

    within_modal do
      click_button 'Delete snippet'
    end

    wait_for_requests

    # This assertion also confirms we did not end up on an error page
    expect(current_url).to end_with(project_snippets_path(project))
    expect(page).to have_link('New snippet')
    expect(page).not_to have_content(snippet.title)
    expect(project.snippets.length).to eq(0)
  end
end
