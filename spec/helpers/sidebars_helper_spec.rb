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
    let(:group) { build(:group) }

    subject { helper.super_sidebar_context(user, group: group, project: nil) }

    before do
      allow(helper).to receive(:current_user) { user }
      Rails.cache.write(['users', user.id, 'assigned_open_issues_count'], 1)
      Rails.cache.write(['users', user.id, 'assigned_open_merge_requests_count'], 2)
      Rails.cache.write(['users', user.id, 'todos_pending_count'], 3)
    end

    it 'returns sidebar values from user', :use_clean_rails_memory_store_caching do
      expect(subject).to include({
        name: user.name,
        username: user.username,
        avatar_url: user.avatar_url,
        assigned_open_issues_count: 1,
        assigned_open_merge_requests_count: 2,
        todos_pending_count: 3,
        issues_dashboard_path: issues_dashboard_path(assignee_username: user.username)
      })
    end

    it 'returns "Create new" menu groups without headers', :use_clean_rails_memory_store_caching do
      expect(subject[:create_new_menu_groups]).to eq([
        {
          name: "",
          items: [
            { href: "/projects/new", text: "New project/repository" },
            { href: "/groups/new", text: "New group" },
            { href: "/-/snippets/new", text: "New snippet" }
          ]
        }
      ])
    end

    it 'returns "Create new" menu groups with headers', :use_clean_rails_memory_store_caching do
      allow(group).to receive(:persisted?).and_return(true)
      allow(helper).to receive(:can?).and_return(true)

      expect(subject[:create_new_menu_groups]).to contain_exactly(
        a_hash_including(
          name: "In this group",
          items: array_including(
            { href: "/projects/new", text: "New project/repository" },
            { href: "/groups/new#create-group-pane", text: "New subgroup" },
            { href: "/groups/#{group.full_path}/-/group_members", text: "Invite members" }
          )
        ),
        a_hash_including(
          name: "In GitLab",
          items: array_including(
            { href: "/projects/new", text: "New project/repository" },
            { href: "/groups/new", text: "New group" },
            { href: "/-/snippets/new", text: "New snippet" }
          )
        )
      )
    end
  end
end
