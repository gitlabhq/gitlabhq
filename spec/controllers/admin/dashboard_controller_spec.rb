# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::DashboardController do
  describe '#index' do
    before do
      sign_in(create(:admin))
    end

    it 'retrieves Redis versions' do
      get :index

      # specs are run against both Redis and Redis Cluster instances.
      expect(assigns[:redis_versions].length).to be > 0
    end

    context 'with pending_delete projects' do
      render_views

      it 'does not retrieve projects that are pending deletion' do
        project = create(:project)
        pending_delete_project = create(:project, pending_delete: true)

        get :index

        expect(response.body).to match(project.name)
        expect(response.body).not_to match(pending_delete_project.name)
      end
    end

    describe 'GitLab KAS', feature_category: :deployment_management do
      before do
        allow(Gitlab::Kas).to receive(:enabled?).and_return(enabled)
      end

      context 'with kas enabled' do
        let(:enabled) { true }

        before do
          response = instance_double(Gitlab::Agent::ServerInfo::ServerInfo)
          allow_next_instance_of(Gitlab::Kas::Client) do |instance|
            allow(instance).to receive(:get_server_info).and_return(response)
          end
        end

        it 'retrieves and displays kas version' do
          get :index

          expect(assigns[:kas_server_info]).to be_present
        end
      end

      context 'with kas disabled' do
        let(:enabled) { false }

        it 'does not retrieve kas source' do
          get :index

          expect(assigns[:kas_server_info]).to be_nil
        end
      end
    end
  end
end
