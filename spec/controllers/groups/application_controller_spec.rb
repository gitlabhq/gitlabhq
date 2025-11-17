# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ApplicationController, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }

  describe '#respond_to_missing?' do
    it 'returns true if the method matches the name structure' do
      expect(controller.respond_to?(:authorize_read_usage_quotas!)).to eq(true)
    end

    it 'returns false if the method does not match the name structure' do
      expect(controller.respond_to?(:does_not_exist)).to eq(false)
    end
  end

  describe '#method_missing' do
    controller do
      before_action :authorize_read_usage_quotas!

      def index
        head :ok
      end
    end

    it 'calls authorize_action! with the policy and renders not_found when user not authorized' do
      group.add_maintainer(user)
      sign_in(user)
      get :index, params: { group_id: group.to_param }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(response.headers['X-GitLab-Custom-Error']).to eq '1'
    end

    it 'calls authorize_action! with the policy and renders OK when user is authorized' do
      group.add_owner(user)
      sign_in(user)
      get :index, params: { group_id: group.to_param }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'for step-up auth' do
    controller do
      before_action :authenticate_user!

      def any_action
        head :ok
      end
    end

    let(:expected_success_status) { :ok }

    subject(:make_request) { get :any_action, params: { group_id: group.to_param }, session: session_data }

    before do
      routes.draw { get 'any_action' => 'groups/application#any_action' }
      sign_in(user)
    end

    it_behaves_like 'enforces step-up authentication'
  end
end
