# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ApplicationController, feature_category: :groups_and_projects do
  controller do
    prepend_before_action :authenticate_user!

    def index
      head :ok
    end
  end

  before do
    routes.draw do
      get 'index' => 'projects/application#index'
    end

    sign_in(user)
  end

  subject(:make_request) do
    get :index, params: { namespace_id: project.namespace, project_id: project }, session: session_data
  end

  describe '#enforce_step_up_auth_for_namespace' do
    context 'with project in group namespace' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be_with_reload(:project) { create(:project, namespace: group) }
      let_it_be(:user, freeze: true) { create(:user, developer_of: project) }

      it_behaves_like 'enforces step-up authentication' do
        let(:expected_success_status) { :ok }
      end
    end

    context 'with project in user namespace (personal projects)' do
      let_it_be(:user_namespace, reload: true) { create(:namespace, :with_namespace_settings) }
      let_it_be_with_reload(:project) { create(:project, namespace: user_namespace) }
      let_it_be(:user, freeze: true) { create(:user, developer_of: project) }

      it_behaves_like 'does not enforce step-up authentication' do
        let(:group) { user_namespace }
        let(:session_data) { nil }
        let(:expected_success_status) { :ok }
      end
    end
  end
end
