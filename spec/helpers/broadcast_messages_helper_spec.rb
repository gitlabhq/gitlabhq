# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BroadcastMessagesHelper do
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  shared_examples 'returns role-targeted broadcast message when in project, group, or sub-group URL' do
    let(:feature_flag_state) { true }

    before do
      stub_feature_flags(role_targeted_broadcast_messages: feature_flag_state)
      allow(helper).to receive(:cookies) { {} }
    end

    context 'when in a project page' do
      let_it_be(:project) { create(:project) }

      before do
        project.add_developer(user)

        assign(:project, project)
        allow(helper).to receive(:controller) { ProjectsController.new }
      end

      it { is_expected.to eq message }

      context 'when feature flag is disabled' do
        let(:feature_flag_state) { false }

        it { is_expected.to be_nil }
      end
    end

    context 'when in a group page' do
      let_it_be(:group) { create(:group) }

      before do
        group.add_developer(user)

        assign(:group, group)
        allow(helper).to receive(:controller) { GroupsController.new }
      end

      it { is_expected.to eq message }

      context 'when feature flag is disabled' do
        let(:feature_flag_state) { false }

        it { is_expected.to be_nil }
      end
    end

    context 'when not in a project, group, or sub-group page' do
      it { is_expected.to be_nil }

      context 'when feature flag is disabled' do
        let(:feature_flag_state) { false }

        it { is_expected.to be_nil }
      end
    end
  end

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

    describe 'user access level targeted messages' do
      let_it_be(:message) { create(:broadcast_message, broadcast_type: 'notification', starts_at: Time.now, target_access_levels: [Gitlab::Access::DEVELOPER]) }

      include_examples 'returns role-targeted broadcast message when in project, group, or sub-group URL'
    end
  end

  describe 'current_broadcast_banner_messages' do
    describe 'user access level targeted messages' do
      let_it_be(:message) { create(:broadcast_message, broadcast_type: 'banner', starts_at: Time.now, target_access_levels: [Gitlab::Access::DEVELOPER]) }

      subject { helper.current_broadcast_banner_messages.first }

      include_examples 'returns role-targeted broadcast message when in project, group, or sub-group URL'
    end
  end

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
