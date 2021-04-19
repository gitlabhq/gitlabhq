# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Jobs Permissions' do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:group) { create(:group, name: 'some group') }
  let_it_be_with_reload(:project) { create(:project, :repository, namespace: group) }
  let_it_be_with_reload(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.sha, ref: 'master') }
  let_it_be(:user) { create(:user) }
  let_it_be(:job) { create(:ci_build, :running, :coverage, :trace_artifact, pipeline: pipeline) }

  before do
    stub_feature_flags(jobs_table_vue: false)

    sign_in(user)

    project.enable_ci
  end

  describe 'jobs pages' do
    shared_examples 'recent job page details responds with status' do |status|
      before do
        visit project_job_path(project, job)
      end

      it { expect(status_code).to eq(status) }
    end

    shared_examples 'project jobs page responds with status' do |status|
      before do
        visit project_jobs_path(project)
      end

      it { expect(status_code).to eq(status) }
    end

    context 'when public access for jobs is disabled' do
      before do
        project.update!(public_builds: false)
      end

      context 'when user is a guest' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'recent job page details responds with status', 404
        it_behaves_like 'project jobs page responds with status', 404
      end

      context 'when project is internal' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        it_behaves_like 'recent job page details responds with status', 404
        it_behaves_like 'project jobs page responds with status', 404
      end
    end

    context 'when public access for jobs is enabled' do
      before do
        project.update!(public_builds: true)
      end

      context 'when user is a guest' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'recent job page details responds with status', 200
        it_behaves_like 'project jobs page responds with status', 200
      end

      context 'when user is a developer' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'recent job page details responds with status', 200
        it_behaves_like 'project jobs page responds with status', 200
      end

      context 'when project is internal' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        it_behaves_like 'recent job page details responds with status', 200 do
          it 'renders job details', :js do
            expect(page).to have_content "Job ##{job.id}"
            expect(page).to have_css '.log-line'
          end
        end

        it_behaves_like 'project jobs page responds with status', 200 do
          it 'renders job' do
            page.within('.build') do
              expect(page).to have_content("##{job.id}")
                .and have_content(job.sha[0..7])
                .and have_content(job.ref)
                .and have_content(job.name)
            end
          end
        end
      end
    end
  end

  describe 'artifacts page' do
    context 'when recent job has artifacts available' do
      before_all do
        archive = fixture_file_upload('spec/fixtures/ci_build_artifacts.zip')

        create(:ci_job_artifact, :archive, file: archive, job: job)
      end

      context 'when public access for jobs is disabled' do
        before do
          project.update!(public_builds: false)
        end

        context 'when user with guest role' do
          before do
            project.add_guest(user)
          end

          it 'responds with 404 status' do
            visit download_project_job_artifacts_path(project, job)

            expect(status_code).to eq(404)
          end
        end

        context 'when user with reporter role' do
          before do
            project.add_reporter(user)
          end

          it 'starts download artifact' do
            visit download_project_job_artifacts_path(project, job)

            expect(status_code).to eq(200)
            expect(page.response_headers['Content-Type']).to eq 'application/zip'
            expect(page.response_headers['Content-Transfer-Encoding']).to eq 'binary'
          end
        end
      end
    end
  end

  context 'with CI_DEBUG_TRACE' do
    let_it_be(:ci_instance_variable) { create(:ci_instance_variable, key: 'CI_DEBUG_TRACE') }

    describe 'trace endpoint' do
      let_it_be(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      where(:public_builds, :user_project_role, :ci_debug_trace, :expected_status_code) do
        true         | 'developer'      | true  | 200
        true         | 'guest'          | true  | 403
        true         | 'developer'      | false | 200
        true         | 'guest'          | false | 200
        false        | 'developer'      | true  | 200
        false        | 'guest'          | true  | 403
        false        | 'developer'      | false | 200
        false        | 'guest'          | false | 403
      end

      with_them do
        before do
          ci_instance_variable.update!(value: ci_debug_trace)
          project.update!(public_builds: public_builds)
          project.add_role(user, user_project_role)
        end

        it 'renders trace to authorized users' do
          visit trace_project_job_path(project, job)

          expect(status_code).to eq(expected_status_code)
        end
      end
    end

    describe 'raw page' do
      let_it_be(:job) { create(:ci_build, :running, :coverage, :trace_artifact, pipeline: pipeline) }

      where(:public_builds, :user_project_role, :ci_debug_trace, :expected_status_code, :expected_msg) do
        true         | 'developer'      | true  | 200 | nil
        true         | 'guest'          | true  | 403 | 'You must have developer or higher permissions'
        true         | 'developer'      | false | 200 | nil
        true         | 'guest'          | false | 200 | nil
        false        | 'developer'      | true  | 200 | nil
        false        | 'guest'          | true  | 403 | 'You must have developer or higher permissions'
        false        | 'developer'      | false | 200 | nil
        false        | 'guest'          | false | 403 | 'The current user is not authorized to access the job log'
      end

      with_them do
        before do
          ci_instance_variable.update!(value: ci_debug_trace)
          project.update!(public_builds: public_builds)
          project.add_role(user, user_project_role)
        end

        it 'renders raw trace to authorized users' do
          visit raw_project_job_path(project, job)

          expect(status_code).to eq(expected_status_code)
          expect(page).to have_content(expected_msg)
        end
      end
    end
  end
end
