# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Thread Comments Issue', :js, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)

    visit project_issue_path(project, issue)
  end

  it 'clicking "Comment and close issue" will post a comment and close the issue, and reopen issue' do
    fill_in 'Add a reply', with: 'Close me!'
    click_button 'Comment and close issue'

    expect(page).to have_css('.gl-badge', text: 'Closed')
    expect(page).to have_css('.note', text: 'Close me!')

    fill_in 'Add a reply', with: 'Reopen me!'
    click_button 'Comment and reopen issue'

    expect(page).to have_css('.gl-badge', text: 'Open')
    expect(page).to have_css('.note', text: 'Reopen me!')
  end
end
