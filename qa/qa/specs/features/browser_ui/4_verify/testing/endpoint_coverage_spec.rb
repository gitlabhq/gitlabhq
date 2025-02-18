# frozen_string_literal: true

module QA
  # Spark various endpoints (git, web, api, sidekiq) to ensure
  # GitLab-QA covers these various endpoints.  The `api_json.log` can then be consumed after test run.
  #
  # User sets a CI variable via UI (Web write) ->
  # Git push (Git read/write) ->
  # pipeline created (Sidekiq read/write) ->
  # runner picks up pipeline (API read/write) ->
  # User views pipeline succeeds (Web read)
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
    context 'Endpoint Coverage' do
      let!(:project) { create(:project, name: 'endpoint-coverage') }
      let!(:runner) { create(:project_runner, project: project, name: project.name, tags: [project.name]) }

      before do
        Flow::Login.sign_in
        project.visit!
      end

      after do
        runner.remove_via_api!
      end

      it(
        'spans r/w postgres web sidekiq git api',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/360837'
      ) do
        # create a CI variable via UI
        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
        Page::Project::Settings::CiCd.perform do |ci_cd|
          ci_cd.expand_ci_variables do |vars|
            vars.click_add_variable
            vars.fill_variable('CI_VARIABLE', 'secret-value')
          end
        end

        # push a .gitlab-ci.yml file that exposes artifacts
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = '.gitlab-ci.yml'
          push.file_content = <<~YAML
            test:
              tags:
                - #{project.name}
              script:
                - mkdir out; echo $CI_VARIABLE > out/file.out
              artifacts:
                paths:
                  - out/
                expire_in: 1h
          YAML
          push.commit_message = 'Commit .gitlab-ci.yml'
        end

        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        project.visit_job('test')

        Page::Project::Job::Show.perform do |show|
          # user views job succeeding
          expect { show.passed? }.to eventually_be_truthy.within(max_duration: 60, sleep_interval: 1)

          show.click_browse_button
        end

        Page::Project::Artifact::Show.perform do |show|
          show.go_to_directory('out')
          expect(show).to have_content('file.out')
        end
      end
    end
  end
end
