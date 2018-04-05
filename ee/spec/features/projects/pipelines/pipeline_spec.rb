require 'spec_helper'

describe 'Pipeline', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    sign_in(user)
    project.add_developer(user)

    allow(License).to receive(:feature_available?).and_return(true)
  end

  describe 'GET /:project/pipelines/:id/security' do
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    context 'with a sast artifact' do
      before do
        create(
          :ci_build,
          :success,
          :artifacts,
          name: 'sast',
          pipeline: pipeline,
          options: {
            artifacts: {
              paths: [Ci::Build::SAST_FILE]
            }
          }
        )

        visit security_project_pipeline_path(project, pipeline)
      end

      it 'shows jobs tab pane as active' do
        expect(page).to have_content('Security report')
        expect(page).to have_css('#js-tab-security')
      end

      it 'shows security report section' do
        expect(page).to have_content('SAST is loading')
      end
    end

    context 'without sast artifact' do
      before do
        visit security_project_pipeline_path(project, pipeline)
      end

      it 'displays the pipeline graph' do
        expect(current_path).to eq(pipeline_path(pipeline))
        expect(page).not_to have_content('Security report')
        expect(page).to have_selector('.pipeline-visualization')
      end
    end
  end
end
