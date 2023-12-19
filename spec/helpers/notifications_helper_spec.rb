# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationsHelper do
  describe 'notification_icon' do
    it { expect(notification_icon(:disabled)).to match('data-testid="notifications-off-icon"') }
    it { expect(notification_icon(:owner_disabled)).to match('data-testid="notifications-off-icon"') }
    it { expect(notification_icon(:participating)).to match('data-testid="notifications-icon"') }
    it { expect(notification_icon(:mention)).to match('data-testid="at-icon"') }
    it { expect(notification_icon(:global)).to match('data-testid="earth-icon') }
    it { expect(notification_icon(:watch)).to match('data-testid="eye-icon"') }
    it { expect(notification_icon(:custom)).to equal('') }
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
