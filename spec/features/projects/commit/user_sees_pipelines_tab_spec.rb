# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit > Pipelines tab', :js, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  describe 'rendering the pipelines table' do
    where(:commit_pipelines_tab_graphql) do
      [true, false]
    end

    with_them do
      before do
        stub_feature_flags(commit_pipelines_tab_graphql: commit_pipelines_tab_graphql)
      end

      context 'when commit has pipelines' do
        let_it_be(:pipeline) do
          create(:ci_pipeline,
            :success,
            project: project,
            ref: project.default_branch,
            sha: project.commit.sha)
        end

        let_it_be(:job) { create(:ci_build, :success, pipeline: pipeline) }
        let_it_be(:manual_job) { create(:ci_build, :manual, pipeline: pipeline) }

        it 'displays pipelines table' do
          visit pipelines_project_commit_path(project, project.commit.id)

          within_testid('pipeline-table-row') do
            expect(page).to have_testid('ci-icon', text: 'Passed')
            expect(page).to have_content(pipeline.id)
            expect(page).to have_testid('pipeline-mini-graph')
            expect(page).to have_testid('pipelines-manual-actions-dropdown')
            expect(page).to have_testid('pipeline-multi-actions-dropdown')
          end

          within('.commit-ci-menu') do
            expect(page).to have_link('Pipelines 1')
          end
        end
      end

      context 'when commit does not have pipelines' do
        before do
          visit project_commit_path(project, project.commit.id)
        end

        it 'does not display pipelines tab link' do
          within('#content-body') do
            expect(page).not_to have_link('Pipelines')
          end
        end
      end
    end
  end
end
