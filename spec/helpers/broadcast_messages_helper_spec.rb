# frozen_string_literal: true

require 'spec_helper'

describe BroadcastMessagesHelper do
  describe 'broadcast_message' do
    let(:current_broadcast_message) { BroadcastMessage.new(message: 'Current Message') }

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
