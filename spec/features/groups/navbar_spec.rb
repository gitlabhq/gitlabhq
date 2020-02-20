# frozen_string_literal: true

require 'spec_helper'

describe 'Group navbar' do
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

  it_behaves_like 'verified navigation bar' do
    before do
      group.add_maintainer(user)
      sign_in(user)

      visit group_path(group)
    end
  end

  if Gitlab.ee?
    context 'when productivity analytics is available' do
      before do
        stub_licensed_features(productivity_analytics: true)

        analytics_nav_item[:nav_sub_items] << _('Productivity Analytics')

        group.add_maintainer(user)
        sign_in(user)

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end
  end
end
