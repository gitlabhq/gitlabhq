# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BroadcastMessageDismissalFinder, '#execute', feature_category: :notifications do
  let_it_be(:user) { create(:user) }
  let_it_be(:message_banner) { create(:broadcast_message, broadcast_type: :banner, message: 'banner') }
  let_it_be(:message_notification) { create(:broadcast_message, :notification, message: 'notification') }
  let_it_be(:other_message) { create(:broadcast_message, message: 'other') }

  let_it_be(:banner_dismissal) { create(:broadcast_message_dismissal, broadcast_message: message_banner, user: user) }
  let_it_be(:notification_dismissal) do
    create(:broadcast_message_dismissal, broadcast_message: message_notification, user: user)
  end

  let(:message_ids) { [message_banner.id, message_notification.id, other_message.id] }

  before_all do
    create(:broadcast_message_dismissal, broadcast_message: other_message, user: build(:user))
  end

  subject(:execute) { described_class.new(user).execute }

  it 'provides valid user dismissals' do
    expect(execute).to match_array([banner_dismissal, notification_dismissal])
  end

  context 'when dismissal is expired' do
    let_it_be(:expired_banner_dismissal) do
      create(:broadcast_message_dismissal, :expired, user: user)
    end

    it 'does not include the expired dismissal' do
      expect(execute).to match_array([banner_dismissal, notification_dismissal])
    end
  end
end
