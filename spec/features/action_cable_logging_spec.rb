# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActionCable logging', :js do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  before_all do
    project.add_developer(user)
  end

  it 'adds extra context to logs' do
    allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original

    expect(ActiveSupport::Notifications).to receive(:instrument).with(
      'connect.action_cable',
      a_hash_including(remote_ip: '127.0.0.1', user_id: nil, username: nil)
    )

    subscription_data = a_hash_including(
      remote_ip: '127.0.0.1',
      user_id: user.id,
      username: user.username
    )

    expect(ActiveSupport::Notifications).to receive(:instrument).with('subscribe.action_cable', subscription_data)

    gitlab_sign_in(user)
    visit project_issue_path(project, issue)

    # Because there is no visual indicator for Capybara to wait on before closing the browser,
    # we need to test an actual feature to ensure that the subscription was already established.

    expect(page.find('.assignee')).to have_content 'None'

    fill_in 'note[note]', with: "/assign #{user.username}"
    click_button 'Comment'

    expect(page.find('.assignee')).to have_content user.name
  end
end
