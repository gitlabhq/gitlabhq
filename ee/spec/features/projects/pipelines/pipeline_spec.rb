require 'spec_helper'

describe 'Pipeline', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_developer(user)
  end

  describe 'GET /:project/pipelines/:id/security' do
    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    let(:build) do
      create(
        :ci_build,
        :artifacts,
        name: 'sast',
        pipeline: pipeline,
        options: {
          artifacts: {
            paths: [Ci::Build::SAST_FILE]
          }
        }
      )
    end

    context 'when there is a sast artifact' do
      before do
        build

        visit security_project_pipeline_path(project, pipeline)
      end

      it 'shows jobs tab pane as active' do
        expect(page).to have_content('Security report')
        expect(page).to have_css('#js-tab-security')
      end

      it 'shows security report' do
        expect(page).to have_content('SAST detected no security vulnerabilities')
      end
    end

    context 'without sast artifact' do
      before do
        visit security_project_pipeline_path(project, pipeline)
      end

      it 'displays the pipeline graph' do
        expect(current_path).to eq(pipeline_path(pipeline))
        expect(page).not_to have_content('Security report')
      end
    end
  end
end
