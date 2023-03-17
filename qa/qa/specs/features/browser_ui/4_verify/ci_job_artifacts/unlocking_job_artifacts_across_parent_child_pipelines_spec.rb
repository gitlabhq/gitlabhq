# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_security, quarantine: {
    issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/396855',
    type: :flaky
  } do
    describe "Unlocking job artifacts across parent-child pipelines" do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'unlock-job-artifacts-parent-child-project'
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let(:parent_test_job_name) { 'test-job-parent' }
      let(:child_test_job_name) { 'test-job-child' }

      let(:previous_successful_pipeline) do
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = project
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
      end

      context 'without strategy:depend' do
        let(:strategy) { nil }

        before do
          add_parent_child_ci_files
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed')
          previous_successful_pipeline
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed')
        end

        context 'when latest pipeline family is successful' do
          before do
            update_parent_child_ci_files
          end

          it 'unlocks job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/395516' do
            project.visit!

            Flow::Pipeline.visit_latest_pipeline(status: 'passed')
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            Flow::Pipeline.visit_latest_pipeline(status: 'passed')
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            previous_successful_pipeline.visit!
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end

            previous_successful_pipeline.visit!
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end
          end
        end

        context 'when latest parent pipeline failed' do
          before do
            update_failed_parent_ci_file
          end

          it 'does not unlock job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396243' do
            project.visit!

            Flow::Pipeline.visit_latest_pipeline(status: 'failed')
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_failed
              # FIXME: this should be unlocked,
              # to be fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110575
              expect(job).to have_locked_artifact
            end

            Flow::Pipeline.visit_latest_pipeline(status: 'failed')
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful
              expect(job).to have_locked_artifact
            end

            previous_successful_pipeline.visit!
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            previous_successful_pipeline.visit!
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end
          end
        end

        context 'when latest child pipeline failed' do
          before do
            update_failed_child_ci_file
          end

          it 'unlocks job artifacts from previous successful pipeline family because the latest parent is successful',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396244' do
            project.visit!

            Flow::Pipeline.visit_latest_pipeline(status: 'passed')
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful
              expect(job).to have_locked_artifact
            end

            Flow::Pipeline.visit_latest_pipeline(status: 'passed')
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_failed
              expect(job).to have_locked_artifact
            end

            previous_successful_pipeline.visit!
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end

            previous_successful_pipeline.visit!
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end
          end
        end
      end

      context 'with strategy:depend' do
        let(:strategy) { 'depend' }

        before do
          add_parent_child_ci_files
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed')
          previous_successful_pipeline
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed')
        end

        context 'when latest pipeline family is successful' do
          before do
            update_parent_child_ci_files
          end

          it 'unlocks job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396245' do
            project.visit!

            Flow::Pipeline.visit_latest_pipeline(status: 'passed')
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            Flow::Pipeline.visit_latest_pipeline(status: 'passed')
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            previous_successful_pipeline.visit!
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end

            previous_successful_pipeline.visit!
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end
          end
        end

        context 'when latest parent pipeline failed' do
          before do
            update_failed_parent_ci_file
          end

          it 'does not unlock job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396246' do
            project.visit!

            Flow::Pipeline.visit_latest_pipeline(status: 'failed')
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              # FIXME: this should be unlocked,
              # to be fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110575
              expect(job).to be_failed
              expect(job).to have_locked_artifact
            end

            Flow::Pipeline.visit_latest_pipeline(status: 'failed')
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful
              expect(job).to have_locked_artifact
            end

            previous_successful_pipeline.visit!
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            previous_successful_pipeline.visit!
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end
          end
        end

        context 'when latest child pipeline failed' do
          before do
            update_failed_child_ci_file
          end

          it 'does not unlock job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396248' do
            project.visit!

            Flow::Pipeline.visit_latest_pipeline(status: 'failed')
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful
              # FIXME: this should be unlocked,
              # to be fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110575
              expect(job).to have_locked_artifact
            end

            Flow::Pipeline.visit_latest_pipeline(status: 'failed')
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_failed
              # FIXME: this should be unlocked,
              # to be fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110575
              expect(job).to have_locked_artifact
            end

            previous_successful_pipeline.visit!
            Flow::Pipeline.visit_pipeline_job_page(job_name: parent_test_job_name)
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            previous_successful_pipeline.visit!
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.expand_child_pipeline
              pipeline.click_job(child_test_job_name)
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end
          end
        end
      end

      private

      def update_parent_child_ci_files
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Update parent and child pipelines CI files.'
          commit.update_files(
            [
              parent_ci_file,
              child_ci_file
            ]
          )
        end
      end

      def update_failed_parent_ci_file
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Fail parent pipeline.'
          commit.update_files(
            [
              parent_failed_ci_file
            ]
          )
        end
      end

      def update_failed_child_ci_file
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Fail child pipeline.'
          commit.update_files(
            [
              child_failed_ci_file
            ]
          )
        end
      end

      def add_parent_child_ci_files
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add parent and child pipelines CI files.'
          commit.add_files(
            [
              parent_ci_file,
              child_ci_file
            ]
          )
        end
      end

      def parent_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            trigger-child:
              stage: test
              trigger:
                include: ".child-ci.yml"
                strategy: #{strategy}

            #{parent_test_job_name}:
              stage: test
              tags: ["#{executor}"]
              script: echo "parent test"
              artifacts:
                paths: ['.gitlab-ci.yml']
                when: always
          YAML
        }
      end

      def parent_failed_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            trigger-child:
              stage: test
              trigger:
                include: ".child-ci.yml"
                strategy: #{strategy}

            #{parent_test_job_name}:
              stage: test
              tags: ["#{executor}"]
              script: echo "parent test" && exit 1
              artifacts:
                paths: ['.gitlab-ci.yml']
                when: always
          YAML
        }
      end

      def child_ci_file
        {
          file_path: '.child-ci.yml',
          content: <<~YAML
            #{child_test_job_name}:
              stage: test
              tags: ["#{executor}"]
              script: echo "child test"
              artifacts:
                paths: ['.child-ci.yml']
                when: always
          YAML
        }
      end

      def child_failed_ci_file
        {
          file_path: '.child-ci.yml',
          content: <<~YAML
            #{child_test_job_name}:
              stage: test
              tags: ["#{executor}"]
              script: echo "child test" && exit 1
              artifacts:
                paths: ['.child-ci.yml']
                when: always
          YAML
        }
      end
    end
  end
end
