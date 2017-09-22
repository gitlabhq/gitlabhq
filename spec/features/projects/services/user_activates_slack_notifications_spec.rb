require 'spec_helper'

describe 'User activates Slack notifications' do
  let(:user) { create(:user) }
  let(:service) { SlackService.new }
  let(:project) { create(:project, slack_service: service) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'when service is not configured yet' do
    before do
      visit(project_settings_integrations_path(project))

      click_link('Slack notifications')
    end

    it 'activates service' do
      check('Active')
      fill_in('Webhook', with: 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685')
      click_button('Save')

      expect(page).to have_content('Slack notifications activated.')
    end
  end

  context 'when service is already configured' do
    before do
      service.fields
      service.update_attributes(
        push_channel: 1,
        issue_channel: 2,
        merge_request_channel: 3,
        note_channel: 4,
        tag_push_channel: 5,
        pipeline_channel: 6,
        wiki_page_channel: 7)

      visit(edit_project_service_path(project, service))
    end

    it 'filters events by channel' do
      expect(page.find_field('service_push_channel').value).to have_content('1')
      expect(page.find_field('service_issue_channel').value).to have_content('2')
      expect(page.find_field('service_merge_request_channel').value).to have_content('3')
      expect(page.find_field('service_note_channel').value).to have_content('4')
      expect(page.find_field('service_tag_push_channel').value).to have_content('5')
      expect(page.find_field('service_pipeline_channel').value).to have_content('6')
      expect(page.find_field('service_wiki_page_channel').value).to have_content('7')
    end
  end
end
