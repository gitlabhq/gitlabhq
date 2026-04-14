# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentsHelper do
  include Gitlab::Routing.url_helpers

  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
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

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?)
      .with(user, :create_incident, project)
      .and_return(can_create_incident)
  end

  describe '#incidents_data' do
    subject(:data) { helper.incidents_data(project, params) }

    shared_examples 'frontend configuration' do
      it 'returns frontend configuration' do
        expect(data).to include(
          'project-path' => project_path,
          'new-issue-path' => new_issue_path,
          'incident-template-name' => 'incident',
          'incident-type' => 'incident',
          'issue-path' => issue_path,
          'empty-list-svg-path' => match_asset_path('/assets/illustrations/empty-state/empty-scan-alert-md.svg'),
          'text-query': 'search text',
          'author-username-query': 'root',
          'assignee-username-query': 'max.power',
          'can-create-incident': can_create_incident.to_s
        )
      end
    end

    context 'when user can create incidents' do
      let(:can_create_incident) { true }

      include_examples 'frontend configuration'
    end

    context 'when user cannot create incidents' do
      let(:can_create_incident) { false }

      include_examples 'frontend configuration'
    end
  end
end
