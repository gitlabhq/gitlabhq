# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Snippets > User deletes a snippet', :js do
  let(:project) { create(:project) }
  let!(:snippet) { create(:project_snippet, :repository, project: project, author: user) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(project_snippet_path(project, snippet))
  end

  it 'deletes a snippet' do
    expect(page).to have_content(snippet.title)

    click_button('Delete')
    click_button('Delete snippet')
    wait_for_requests

    # This assertion also confirms we did not end up on an error page
    expect(page).to have_selector('#new_snippet_link')
    expect(project.snippets.length).to eq(0)
  end
end
