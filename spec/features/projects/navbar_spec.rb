# frozen_string_literal: true

require 'spec_helper'

describe 'Project navbar' do
  it_behaves_like 'verified navigation bar' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }

    let(:structure) do
      [
        {
          nav_item: _('Project overview'),
          nav_sub_items: [
            _('Details'),
            _('Activity'),
            _('Releases')
          ]
        },
        {
          nav_item: _('Repository'),
          nav_sub_items: [
            _('Files'),
            _('Commits'),
            _('Branches'),
            _('Tags'),
            _('Contributors'),
            _('Graph'),
            _('Compare'),
            (_('Locked Files') if Gitlab.ee?)
          ]
        },
        {
          nav_item: _('Issues'),
          nav_sub_items: [
            _('List'),
            _('Boards'),
            _('Labels'),
            _('Milestones')
          ]
        },
        {
          nav_item: _('Merge Requests'),
          nav_sub_items: []
        },
        {
          nav_item: _('CI / CD'),
          nav_sub_items: [
            _('Pipelines'),
            _('Jobs'),
            _('Artifacts'),
            _('Schedules')
          ]
        },
        {
          nav_item: _('Operations'),
          nav_sub_items: [
            _('Metrics'),
            _('Environments'),
            _('Error Tracking'),
            _('Serverless'),
            _('Kubernetes')
          ]
        },
        {
          nav_item: _('Analytics'),
          nav_sub_items: [
            _('CI / CD Analytics'),
            (_('Code Review') if Gitlab.ee?),
            _('Repository Analytics'),
            _('Value Stream Analytics')
          ]
        },
        {
          nav_item: _('Wiki'),
          nav_sub_items: []
        },
        {
          nav_item: _('Snippets'),
          nav_sub_items: []
        },
        {
          nav_item: _('Settings'),
          nav_sub_items: [
            _('General'),
            _('Members'),
            _('Integrations'),
            _('Repository'),
            _('CI / CD'),
            _('Operations'),
            (_('Audit Events') if Gitlab.ee?)
          ].compact
        }
      ]
    end

    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_path(project)
    end
  end
end
