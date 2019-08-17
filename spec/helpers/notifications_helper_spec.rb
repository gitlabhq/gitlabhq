require 'spec_helper'

describe NotificationsHelper do
  describe 'notification_icon' do
    it { expect(notification_icon(:disabled)).to match('class="fa fa-microphone-slash fa-fw"') }
    it { expect(notification_icon(:owner_disabled)).to match('class="fa fa-microphone-slash fa-fw"') }
    it { expect(notification_icon(:participating)).to match('class="fa fa-volume-up fa-fw"') }
    it { expect(notification_icon(:mention)).to match('class="fa fa-at fa-fw"') }
    it { expect(notification_icon(:global)).to match('class="fa fa-globe fa-fw"') }
    it { expect(notification_icon(:watch)).to match('class="fa fa-eye fa-fw"') }
  end

  describe 'notification_title' do
    it { expect(notification_title(:watch)).to match('Watch') }
    it { expect(notification_title(:mention)).to match('On mention') }
    it { expect(notification_title(:global)).to match('Global') }
  end

  describe '#notification_event_name' do
    it { expect(notification_event_name(:success_pipeline)).to match('Successful pipeline') }
    it { expect(notification_event_name(:failed_pipeline)).to match('Failed pipeline') }
  end

  describe '#notification_icon_level' do
    let(:user) { create(:user) }
    let(:global_setting) { user.global_notification_setting }
    let(:notification_setting) { create(:notification_setting, level: :watch) }

    it { expect(notification_icon_level(notification_setting, true)).to eq 'owner_disabled' }
    it { expect(notification_icon_level(notification_setting)).to eq 'watch' }
    it { expect(notification_icon_level(global_setting)).to eq 'participating' }
  end
end
