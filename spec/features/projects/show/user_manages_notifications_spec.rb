require 'spec_helper'

describe 'Projects > Show > User manages notifications', :js do
  let(:project) { create(:project, :public, :repository) }

  before do
    sign_in(project.owner)
    visit project_path(project)
  end

  it 'changes the notification setting' do
    first('.notifications-btn').click
    click_link 'On mention'

    page.within '#notifications-button' do
      expect(page).to have_content 'On mention'
    end
  end

  context 'custom notification settings' do
    let(:email_events) do
      [
        :new_note,
        :new_issue,
        :reopen_issue,
        :close_issue,
        :reassign_issue,
        :issue_due,
        :new_merge_request,
        :push_to_merge_request,
        :reopen_merge_request,
        :close_merge_request,
        :reassign_merge_request,
        :merge_merge_request,
        :failed_pipeline,
        :success_pipeline
      ]
    end

    it 'shows notification settings checkbox' do
      first('.notifications-btn').click
      page.find('a[data-notification-level="custom"]').click

      page.within('.custom-notifications-form') do
        email_events.each do |event_name|
          expect(page).to have_selector("input[name='notification_setting[#{event_name}]']")
        end
      end
    end
  end
end
