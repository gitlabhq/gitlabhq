# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BroadcastMessagesHelper do
  describe 'current_broadcast_notification_message' do
    subject { helper.current_broadcast_notification_message }

    context 'with available broadcast notification messages' do
      let!(:broadcast_message_1) { create(:broadcast_message, broadcast_type: 'notification', starts_at: Time.now - 1.day) }
      let!(:broadcast_message_2) { create(:broadcast_message, broadcast_type: 'notification', starts_at: Time.now) }

      it { is_expected.to eq broadcast_message_2 }

      context 'when last broadcast message is hidden' do
        before do
          helper.request.cookies["hide_broadcast_message_#{broadcast_message_2.id}"] = 'true'
        end

        it { is_expected.to eq broadcast_message_1 }
      end
    end

    context 'without broadcast notification messages' do
      it { is_expected.to be_nil }
    end
  end

  describe 'broadcast_message' do
    let_it_be(:user) { create(:user) }

    let(:current_broadcast_message) { BroadcastMessage.new(message: 'Current Message') }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns nil when no current message' do
      expect(helper.broadcast_message(nil)).to be_nil
    end

    it 'includes the current message' do
      allow(helper).to receive(:broadcast_message_style).and_return(nil)

      expect(helper.broadcast_message(current_broadcast_message)).to include 'Current Message'
    end

    it 'includes custom style' do
      allow(helper).to receive(:broadcast_message_style).and_return('foo')

      expect(helper.broadcast_message(current_broadcast_message)).to include 'style="foo"'
    end
  end

  describe 'broadcast_message_style' do
    it 'defaults to no style' do
      broadcast_message = spy

      expect(helper.broadcast_message_style(broadcast_message)).to eq ''
    end

    it 'allows custom style for banner messages' do
      broadcast_message = BroadcastMessage.new(color: '#f2dede', font: '#b94a48', broadcast_type: "banner")

      expect(helper.broadcast_message_style(broadcast_message))
        .to match('background-color: #f2dede; color: #b94a48')
    end

    it 'does not add style for notification messages' do
      broadcast_message = BroadcastMessage.new(color: '#f2dede', broadcast_type: "notification")

      expect(helper.broadcast_message_style(broadcast_message)).to eq ''
    end
  end

  describe 'broadcast_message_status' do
    it 'returns Active' do
      message = build(:broadcast_message)

      expect(helper.broadcast_message_status(message)).to eq 'Active'
    end

    it 'returns Expired' do
      message = build(:broadcast_message, :expired)

      expect(helper.broadcast_message_status(message)).to eq 'Expired'
    end

    it 'returns Pending' do
      message = build(:broadcast_message, :future)

      expect(helper.broadcast_message_status(message)).to eq 'Pending'
    end
  end
end
