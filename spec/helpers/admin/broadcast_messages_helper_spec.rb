# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::BroadcastMessagesHelper, feature_category: :notifications do
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  shared_examples 'returns role-targeted broadcast message when in project, group, or sub-group URL' do
    before do
      allow(helper).to receive(:cookies).and_return({})
    end

    context 'when in a project page' do
      let_it_be(:project) { create(:project) }

      before do
        project.add_developer(user)

        assign(:project, project)
        allow(helper).to receive(:controller) { ProjectsController.new }
      end

      it { is_expected.to eq message }
    end

    context 'when in a group page' do
      let_it_be(:group) { create(:group) }

      before do
        group.add_developer(user)

        assign(:group, group)
        allow(helper).to receive(:controller) { GroupsController.new }
      end

      it { is_expected.to eq message }
    end

    context 'when not in a project, group, or sub-group page' do
      it { is_expected.to be_nil }
    end
  end

  describe '#current_broadcast_notification_message' do
    subject { helper.current_broadcast_notification_message }

    context 'with available broadcast notification messages' do
      let!(:broadcast_message_1) do
        create(:broadcast_message, broadcast_type: 'notification', starts_at: Time.now - 1.day)
      end

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
      let_it_be(:message) do
        create(:broadcast_message,
          broadcast_type: 'notification',
          starts_at: Time.now,
          target_access_levels: [Gitlab::Access::DEVELOPER]
        )
      end

      include_examples 'returns role-targeted broadcast message when in project, group, or sub-group URL'
    end
  end

  describe '#current_broadcast_banner_messages' do
    describe 'user access level targeted messages' do
      let_it_be(:message) do
        create(:broadcast_message,
          broadcast_type: 'banner',
          starts_at: Time.now,
          target_access_levels: [Gitlab::Access::DEVELOPER]
        )
      end

      subject { helper.current_broadcast_banner_messages.first }

      include_examples 'returns role-targeted broadcast message when in project, group, or sub-group URL'
    end
  end

  describe '#broadcast_message' do
    let(:current_broadcast_message) { build(:broadcast_message, message: 'Current Message') }

    it 'returns nil when no current message' do
      expect(helper.broadcast_message(nil)).to be_nil
    end

    it 'includes the current message' do
      expect(helper.broadcast_message(current_broadcast_message)).to include 'Current Message'
    end
  end

  describe '#broadcast_message_status' do
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

  describe '#render_broadcast_message' do
    context 'when message is banner' do
      let_it_be(:broadcast_message) do
        System::BroadcastMessage.new(message: 'Current Message', broadcast_type: :banner)
      end.freeze

      it 'renders broadcast message' do
        expect(helper.render_broadcast_message(broadcast_message)).to eq("<p>Current Message</p>")
      end
    end

    context 'when message is notification' do
      let_it_be(:broadcast_message) do
        System::BroadcastMessage.new(message: 'Current Message', broadcast_type: :notification)
      end.freeze

      it 'renders broadcast message' do
        expect(helper.render_broadcast_message(broadcast_message)).to eq("<p>Current Message</p>")
      end
    end
  end

  describe '#target_access_levels_display' do
    let_it_be(:access_levels) { [Gitlab::Access::REPORTER, Gitlab::Access::DEVELOPER] }.freeze

    it 'joins access levels' do
      expect(helper.target_access_levels_display(access_levels)).to eq("Reporter, Developer")
    end
  end

  describe '#admin_broadcast_messages_data' do
    let(:starts_at) { 1.day.ago }
    let(:ends_at) { 1.day.from_now }
    let(:message) { build(:broadcast_message, id: non_existing_record_id, starts_at: starts_at, ends_at: ends_at) }

    subject(:single_broadcast_message) { Gitlab::Json.parse(admin_broadcast_messages_data([message])).first }

    it 'returns the expected messages data attributes' do
      keys = %w[
        id
        status
        message
        theme
        broadcast_type
        dismissable
        starts_at
        ends_at
        target_roles
        target_path
        type edit_path
        delete_path
      ]

      expect(single_broadcast_message.keys).to match(keys)
    end

    it 'has the correct iso formatted date', time_travel_to: '2020-01-01 00:00:00 +0000' do
      expect(single_broadcast_message['starts_at']).to eq('2019-12-31T00:00:00Z')
      expect(single_broadcast_message['ends_at']).to eq('2020-01-02T00:00:00Z')
    end
  end

  describe '#broadcast_message_data' do
    let(:starts_at) { 1.day.ago }
    let(:ends_at) { 1.day.from_now }
    let(:message) { build(:broadcast_message, id: non_existing_record_id, starts_at: starts_at, ends_at: ends_at) }

    it 'returns the expected message data attributes' do
      keys = [
        :id, :message, :broadcast_type, :theme, :dismissable, :target_access_levels, :messages_path,
        :preview_path, :target_path, :starts_at, :ends_at, :target_access_level_options, :show_in_cli
      ]

      expect(broadcast_message_data(message).keys).to match(keys)
    end

    it 'has the correct iso formatted date', time_travel_to: '2020-01-01 00:00:00 +0000' do
      expect(broadcast_message_data(message)[:starts_at]).to eq('2019-12-31T00:00:00Z')
      expect(broadcast_message_data(message)[:ends_at]).to eq('2020-01-02T00:00:00Z')
    end
  end
end
