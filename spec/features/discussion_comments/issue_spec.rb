# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Thread Comments Issue', :js, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    project.add_maintainer(user)
    sign_in(user)

    visit project_issue_path(project, issue)
  end

  it 'clicking "Comment & close issue" will post a comment and close the issue, and reopen issue' do
    fill_in 'Add a reply', with: 'Close me!'
    click_button 'Comment & close issue'

    expect(page).to have_css('.note', text: 'Close me!')
    expect(page).to have_css('.system-note', text: "#{user.name} closed")
    expect(page).to have_css('.gl-badge', text: 'Closed')

    fill_in 'Add a reply', with: 'Reopen me!'
    click_button 'Comment & reopen issue'

    expect(page).to have_css('.note', text: 'Reopen me!')
    expect(page).to have_css('.system-note', text: "#{user.name} reopened")
    expect(page).to have_css('.gl-badge', text: 'Open')
  end
end
