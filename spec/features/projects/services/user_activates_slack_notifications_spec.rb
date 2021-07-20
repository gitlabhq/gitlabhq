# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Slack notifications', :js do
  include_context 'project service activation'

  context 'when service is not configured yet' do
    before do
      visit_project_integration('Slack notifications')
    end

    it 'activates service' do
      fill_in('Webhook', with: 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685')

      click_test_then_save_integration

      expect(page).to have_content('Slack notifications settings saved and active.')
    end
  end

  context 'when service is already configured' do
    let(:integration) { Integrations::Slack.new }
    let(:project) { create(:project, slack_integration: integration) }

    before do
      integration.fields
      integration.update!(
        push_channel: 1,
        issue_channel: 2,
        merge_request_channel: 3,
        note_channel: 4,
        tag_push_channel: 5,
        pipeline_channel: 6,
        wiki_page_channel: 7)

      visit(edit_project_service_path(project, integration))
    end

    it 'filters events by channel' do
      expect(page.find_field(name: 'service[push_channel]').value).to have_content('1')
      expect(page.find_field(name: 'service[issue_channel]').value).to have_content('2')
      expect(page.find_field(name: 'service[merge_request_channel]').value).to have_content('3')
      expect(page.find_field(name: 'service[note_channel]').value).to have_content('4')
      expect(page.find_field(name: 'service[tag_push_channel]').value).to have_content('5')
      expect(page.find_field(name: 'service[pipeline_channel]').value).to have_content('6')
      expect(page.find_field(name: 'service[wiki_page_channel]').value).to have_content('7')
    end
  end
end
