require 'spec_helper'

describe NotificationsHelper do
  describe 'notification_icon' do
    it { expect(notification_icon(:disabled)).to match('class="fa fa-microphone-slash fa-fw"') }
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
end
