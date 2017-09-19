require 'spec_helper'

describe 'User comments on a snippet', :js do
  let(:project) { create(:project) }
  let!(:snippet) { create(:project_snippet, project: project, author: user) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_snippet_path(project, snippet))
  end

  it 'leaves a comment on a snippet' do
    page.within('.js-main-target-form') do
      fill_in('note_note', with: 'Good snippet!')
      click_button('Comment')
    end

    wait_for_requests

    expect(page).to have_content('Good snippet!')
  end
end
