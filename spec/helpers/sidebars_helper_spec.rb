# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidebarsHelper do
  include Devise::Test::ControllerHelpers

  describe '#sidebar_tracking_attributes_by_object' do
    subject { helper.sidebar_tracking_attributes_by_object(object) }

    before do
      stub_application_setting(snowplow_enabled: true)
    end

    context 'when object is a project' do
      let(:object) { build(:project) }

      it 'returns tracking attrs for project' do
        expect(subject[:data]).to eq({ track_label: 'projects_side_navigation', track_property: 'projects_side_navigation', track_action: 'render' })
      end
    end

    context 'when object is a group' do
      let(:object) { build(:group) }

      it 'returns tracking attrs for group' do
        expect(subject[:data]).to eq({ track_label: 'groups_side_navigation', track_property: 'groups_side_navigation', track_action: 'render' })
      end
    end

    context 'when object is a user' do
      let(:object) { build(:user) }

      it 'returns tracking attrs for user' do
        expect(subject[:data]).to eq({ track_label: 'user_side_navigation', track_property: 'user_side_navigation', track_action: 'render' })
      end
    end

    context 'when object is something else' do
      let(:object) { build(:ci_pipeline) }

      it 'returns no attributes' do
        expect(subject).to eq({})
      end
    end
  end

  describe '#super_sidebar_context' do
    let(:user) { build(:user) }

    subject { helper.super_sidebar_context(user) }

    it 'returns sidebar values from user', :use_clean_rails_memory_store_caching do
      Rails.cache.write(['users', user.id, 'assigned_open_issues_count'], 1)
      Rails.cache.write(['users', user.id, 'assigned_open_merge_requests_count'], 2)
      Rails.cache.write(['users', user.id, 'todos_pending_count'], 3)

      expect(subject).to eq({
        name: user.name,
        username: user.username,
        avatar_url: user.avatar_url,
        assigned_open_issues_count: 1,
        assigned_open_merge_requests_count: 2,
        todos_pending_count: 3,
        issues_dashboard_path: issues_dashboard_path(assignee_username: user.username)
      })
    end
  end
end
