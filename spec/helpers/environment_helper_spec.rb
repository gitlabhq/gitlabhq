# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentHelper, feature_category: :environment_management do
  describe '#environments_detail_data_json' do
    subject { helper.environments_detail_data_json(user, project, environment) }

    let_it_be(:auto_stop_at) { Time.now.utc }
    let_it_be(:user) { create(:user) }
    let_it_be(:project, reload: true) { create(:project, :repository) }
    let_it_be(:environment) do
      create(:environment, project: project, auto_stop_at: auto_stop_at, description: '_description_')
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'returns the correct data' do
      expect(subject).to eq({
        name: environment.name,
        id: environment.id,
        project_full_path: project.full_path,
        base_path: project_environment_path(project, environment),
        external_url: environment.external_url,
        can_update_environment: true,
        can_destroy_environment: true,
        can_stop_environment: true,
        can_admin_environment: true,
        environments_fetch_path: project_environments_path(project, format: :json),
        environment_edit_path: edit_project_environment_path(project, environment),
        environment_stop_path: stop_project_environment_path(project, environment),
        environment_delete_path: environment_delete_path(environment),
        environment_cancel_auto_stop_path: cancel_auto_stop_project_environment_path(project, environment),
        environment_terminal_path: terminal_project_environment_path(project, environment),
        has_terminals: false,
        is_environment_available: true,
        description_html: '<p data-sourcepos="1:1-1:13" dir="auto"><em data-sourcepos="1:1-1:13">description</em></p>',
        auto_stop_at: auto_stop_at,
        graphql_etag_key: environment.etag_cache_key
      }.to_json)
    end
  end
end
