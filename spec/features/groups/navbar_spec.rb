# frozen_string_literal: true

require 'spec_helper'

describe 'Group navbar' do
  it_behaves_like 'verified navigation bar' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    let(:analytics_nav_item) do
      {
        nav_item: _('Analytics'),
        nav_sub_items: [
          _('Contribution Analytics')
        ]
      }
    end

    let(:structure) do
      [
        {
          nav_item: _('Group overview'),
          nav_sub_items: [
            _('Details'),
            _('Activity')
          ]
        },
        {
          nav_item: _('Issues'),
          nav_sub_items: [
            _('List'),
            _('Board'),
            _('Labels'),
            _('Milestones')
          ]
        },
        {
          nav_item: _('Merge Requests'),
          nav_sub_items: []
        },
        {
          nav_item: _('Kubernetes'),
          nav_sub_items: []
        },
        (analytics_nav_item if Gitlab.ee?),
        {
          nav_item: _('Members'),
          nav_sub_items: []
        }
      ]
    end

    before do
      group.add_maintainer(user)
      sign_in(user)

      visit group_path(group)
    end
  end
end
