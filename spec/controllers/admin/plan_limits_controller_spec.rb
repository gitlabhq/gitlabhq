# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PlanLimitsController do
  let_it_be(:plan) { create(:plan) }
  let_it_be(:plan_limits) { create(:plan_limits, plan: plan) }

  describe 'POST create' do
    let(:params) do
      {
        plan_limits: {
          plan_id: plan.id,
          conan_max_file_size: file_size, id: plan_limits.id
        }
      }
    end

    context 'with an authenticated admin user' do
      let(:file_size) { 10.megabytes }

      it 'updates the plan limits', :aggregate_failures do
        sign_in(create(:admin))

        post :create, params: params

        expect(response).to redirect_to(general_admin_application_settings_path)
        expect(plan_limits.reload.conan_max_file_size).to eq(file_size)
      end
    end

    context "when pipeline_hierarchy_size is passed in params" do
      let(:params) do
        {
          plan_limits: {
            plan_id: plan.id,
            pipeline_hierarchy_size: 200, id: plan_limits.id
          }
        }
      end

      it "updates the pipeline_hierarchy_size plan limit" do
        sign_in(create(:admin))

        post :create, params: params

        expect(response).to redirect_to(general_admin_application_settings_path)
        expect(plan_limits.reload.pipeline_hierarchy_size).to eq(params[:plan_limits][:pipeline_hierarchy_size])
      end
    end

    context 'without admin access' do
      let(:file_size) { 1.megabytes }

      it 'returns `not_found`' do
        sign_in(create(:user))

        post :create, params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(plan_limits.conan_max_file_size).not_to eq(file_size)
      end
    end
  end
end
