# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GraphsController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe '#show' do
    subject { get(:show, params: params) }

    let(:params) { { namespace_id: project.namespace.path, project_id: project.path, id: 'master' } }

    describe 'ref_type' do
      it 'assigns ref_type' do
        subject

        expect(assigns[:languages]).to be_nil
      end

      context 'when ref_type is provided' do
        before do
          params[:ref_type] = 'heads'
        end

        it 'assigns ref_type' do
          subject

          expect(assigns[:ref_type]).to eq('heads')
        end
      end
    end

    describe 'when format is json' do
      let(:stubbed_limit) { 1 }

      before do
        params[:format] = 'json'
        stub_const('Projects::GraphsController::MAX_COMMITS', stubbed_limit)
      end

      it 'renders json' do
        subject

        expect(json_response.size).to eq(stubbed_limit)
        %w[author_name author_email date].each do |key|
          expect(json_response[0]).to have_key(key)
        end
      end
    end
  end

  describe 'GET languages' do
    it "redirects_to action charts" do
      get(:commits, params: { namespace_id: project.namespace.path, project_id: project.path, id: 'master' })

      expect(response).to redirect_to action: :charts
    end
  end

  describe 'GET commits' do
    it "redirects_to action charts" do
      get(:commits, params: { namespace_id: project.namespace.path, project_id: project.path, id: 'master' })

      expect(response).to redirect_to action: :charts
    end
  end

  describe 'charts' do
    context 'with an anonymous user' do
      let(:project) { create(:project, :repository, :public) }

      before do
        sign_out(user)
      end

      it 'renders charts with 200 status code' do
        get(:charts, params: { namespace_id: project.namespace.path, project_id: project.path, id: 'master' })

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:charts)
      end

      context 'when anonymous users can read build report results' do
        it 'sets the daily coverage options' do
          freeze_time do
            get(:charts, params: { namespace_id: project.namespace.path, project_id: project.path, id: 'master' })

            expect(assigns[:daily_coverage_options]).to eq(
              base_params: {
                start_date: Date.current - 90.days,
                end_date: Date.current,
                ref_path: project.repository.expand_ref('master'),
                param_type: 'coverage'
              },
              download_path: namespace_project_ci_daily_build_group_report_results_path(
                namespace_id: project.namespace,
                project_id: project,
                format: :csv
              ),
              graph_api_path: namespace_project_ci_daily_build_group_report_results_path(
                namespace_id: project.namespace,
                project_id: project,
                format: :json
              )
            )
          end
        end
      end

      context 'when anonymous users cannot read build report results' do
        before do
          project.update_column(:public_builds, false)

          get(:charts, params: { namespace_id: project.namespace.path, project_id: project.path, id: 'master' })
        end

        it 'does not set daily coverage options' do
          expect(assigns[:daily_coverage_options]).to be_nil
        end
      end

      it_behaves_like 'tracking unique visits', :charts do
        before do
          sign_in(user)
        end

        let(:request_params) { { namespace_id: project.namespace.path, project_id: project.path, id: 'master' } }
        let(:target_id) { 'p_analytics_repo' }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject do
          sign_in(user)
          get :charts, params: request_params, format: :html
        end

        let(:request_params) { { namespace_id: project.namespace.path, project_id: project.path, id: 'master' } }
        let(:category) { described_class.name }
        let(:action) { 'perform_analytics_usage_action' }
        let(:namespace) { project.namespace }
        let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
        let(:property) { 'p_analytics_repo' }
      end
    end

    context 'when languages were previously detected' do
      let(:project) { create(:project, :repository, detected_repository_languages: true) }
      let!(:repository_language) { create(:repository_language, project: project) }

      it 'sets the languages properly' do
        get(:charts, params: { namespace_id: project.namespace.path, project_id: project.path, id: 'master' })

        expect(assigns[:languages]).to eq(
          [value: repository_language.share,
           label: repository_language.name,
           color: repository_language.color,
           highlight: repository_language.color])
      end
    end
  end
end
