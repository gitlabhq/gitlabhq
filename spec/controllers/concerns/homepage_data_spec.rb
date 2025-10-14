# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HomepageData, feature_category: :notifications do
  let(:user) { create(:user) }
  let(:controller_class) do
    Class.new do
      include HomepageData
      include MergeRequestsHelper
      include Rails.application.routes.url_helpers
    end
  end

  let(:controller) { controller_class.new }
  let(:helpers_proxy) { instance_double(ApplicationHelper) }

  before do
    allow(controller).to receive_messages(current_user: user, can?: true)
    allow(controller).to receive(:helpers).and_return(helpers_proxy)

    # Mock the routing helper methods that the concern uses
    allow(controller).to receive_messages(
      merge_requests_dashboard_path: '/merge_requests',
      activity_dashboard_path: '/activity',
      issues_dashboard_path: '/issues',
      dashboard_list_title: 'Test Title'
    )
  end

  describe '#merge_request_ids' do
    subject(:merge_request_ids) { controller.send(:merge_request_ids, user) }

    context 'when user preference is action_based' do
      before do
        user.user_preference.update!(merge_request_dashboard_list_type: 'action_based')
      end

      it 'returns action_based IDs' do
        expect(merge_request_ids).to eq(%w[reviews_requested assigned_to_you])
      end
    end

    context 'when user preference is role_based' do
      before do
        user.user_preference.update!(merge_request_dashboard_list_type: 'role_based')
      end

      it 'returns role_based IDs' do
        expect(merge_request_ids).to eq(%w[reviews assigned])
      end
    end
  end

  describe '#homepage_app_data' do
    subject(:homepage_data) { controller.send(:homepage_app_data, user) }

    context 'when user has a recent push event' do
      let(:project) { build(:project, :repository) }
      let(:push_event) do
        create(:push_event, project: project, author: user).tap do |event|
          # Create a push event payload with the ref information
          create(:push_event_payload, event: event, ref: 'refs/heads/feature-branch')
        end
      end

      before do
        project.add_developer(user)
        allow(user).to receive(:recent_push).and_return(push_event)
      end

      context 'when push event should show widget' do
        before do
          allow(helpers_proxy).to receive(:show_last_push_widget?).with(push_event).and_return(true)
          allow(controller).to receive(:create_mr_button_from_event?).with(push_event).and_return(true)
          allow(controller).to receive(:create_mr_path_from_push_event).with(push_event).and_return('/test/path')
        end

        it 'includes last push widget data' do
          event_data = Gitlab::Json.parse(homepage_data[:last_push_event])
          expect(event_data["show_widget"]).to be(true)
          expect(event_data["create_mr_path"]).to eq('/test/path')
        end

        it 'includes event data as JSON' do
          event_data = Gitlab::Json.parse(homepage_data[:last_push_event])
          expect(event_data['ref_name']).to eq(push_event.ref_name)
          expect(event_data['project']['web_url']).to eq(project.web_url)
          expect(event_data['id']).to eq(push_event.id)
        end
      end

      context 'when push event should not show widget' do
        before do
          allow(helpers_proxy).to receive(:show_last_push_widget?).with(push_event).and_return(false)
          allow(controller).to receive(:create_mr_button_from_event?).with(push_event).and_return(true)
          allow(controller).to receive(:create_mr_path_from_push_event).with(push_event).and_return('/test/path')
        end

        it 'does not include last push widget data' do
          event_data = Gitlab::Json.parse(homepage_data[:last_push_event])
          expect(event_data['id']).to eq(push_event.id)
          expect(event_data["show_widget"]).to be(false)
          expect(event_data["create_mr_path"]).to eq('/test/path')
        end
      end

      context 'when create MR button should not be shown' do
        before do
          allow(helpers_proxy).to receive(:show_last_push_widget?).with(push_event).and_return(true)
          allow(controller).to receive(:create_mr_button_from_event?).with(push_event).and_return(false)
        end

        it 'shows widget but not create MR button' do
          event_data = Gitlab::Json.parse(homepage_data[:last_push_event])
          expect(event_data['id']).to eq(push_event.id)
          expect(event_data["show_widget"]).to be(true)
          expect(event_data["create_mr_path"]).to eq('')
        end
      end
    end

    context 'when user has no recent push event' do
      before do
        allow(user).to receive(:recent_push).and_return(nil)
      end

      it 'does not include last push widget data' do
        event_data = Gitlab::Json.parse(homepage_data[:last_push_event])
        expect(event_data).to be_nil
      end
    end
  end
end
