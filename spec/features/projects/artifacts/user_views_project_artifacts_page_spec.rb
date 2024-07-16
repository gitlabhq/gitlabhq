# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'User views project artifacts page', :js, feature_category: :job_artifacts do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let_it_be(:job_with_artifacts) { create(:ci_build, :artifacts, name: 'test1', pipeline: pipeline) }
  let_it_be(:job_with_trace) { create(:ci_build, :trace_artifact, name: 'test3', pipeline: pipeline) }
  let_it_be(:job_without_artifacts) { create(:ci_build, name: 'test2', pipeline: pipeline) }

  let(:path) { project_artifacts_path(project) }

  context 'when browsing artifacts page' do
    before do
      visit(path)

      wait_for_requests
    end

    it 'lists the project jobs and their artifacts' do
      page.within('main#content-body') do
        page.within('table thead') do
          expect(page).to have_content('Artifacts')
            .and have_content('Job')
            .and have_content('Size')
        end

        find_all('[data-testid="job-artifacts-count"').each(&:click)

        expect(page).to have_content(job_with_artifacts.name)
        expect(page).to have_content(job_with_trace.name)
        expect(page).not_to have_content(job_without_artifacts.name)

        expect(page).to have_content('archive').and have_content('metadata')
        expect(page).to have_content('trace')
      end
    end
  end
end
