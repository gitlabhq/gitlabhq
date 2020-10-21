# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentsHelper do
  include Gitlab::Routing.url_helpers

  let(:project) { create(:project) }
  let(:project_path) { project.full_path }
  let(:new_issue_path) { new_project_issue_path(project) }
  let(:issue_path) { project_issues_path(project) }
  let(:params) do
    {
      search: 'search text',
      author_username: 'root',
      assignee_username: 'max.power'
    }
  end

  describe '#incidents_data' do
    subject(:data) { helper.incidents_data(project, params) }

    it 'returns frontend configuration' do
      expect(data).to include(
        'project-path' => project_path,
        'new-issue-path' => new_issue_path,
        'incident-template-name' => 'incident',
        'incident-type' => 'incident',
        'issue-path' => issue_path,
        'empty-list-svg-path' => match_asset_path('/assets/illustrations/incident-empty-state.svg'),
        'text-query': 'search text',
        'author-username-query': 'root',
        'assignee-username-query': 'max.power'
      )
    end
  end
end
