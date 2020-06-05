# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GraphsController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
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
          Timecop.freeze do
            get(:charts, params: { namespace_id: project.namespace.path, project_id: project.path, id: 'master' })

            expect(assigns[:daily_coverage_options]).to eq(
              base_params: {
                start_date: Time.current.to_date - 90.days,
                end_date: Time.current.to_date,
                ref_path: project.repository.expand_ref('master'),
                param_type: 'coverage'
              },
              download_path: namespace_project_ci_daily_build_group_report_results_path(
                namespace_id: project.namespace,
                project_id: project,
                format: :csv
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
