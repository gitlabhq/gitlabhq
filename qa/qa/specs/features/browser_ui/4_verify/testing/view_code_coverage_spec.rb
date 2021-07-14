# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner do
    describe 'Code coverage statistics' do
      let(:simplecov) { '\(\d+.\d+\%\) covered' }
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:runner) do
        Resource::Runner.fabricate_via_api! do |runner|
          runner.name = executor
          runner.tags = ['e2e-test']
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = runner.project
          mr.file_name = '.gitlab-ci.yml'
          mr.file_content = <<~EOF
            test:
              tags: [e2e-test]
              script:
                - echo '(66.67%) covered'
          EOF
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
      end

      it 'creates an MR with code coverage statistics', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1740' do
        runner.project.visit!
        configure_code_coverage(simplecov)
        merge_request.visit!

        Page::MergeRequest::Show.perform do |mr_widget|
          Support::Retrier.retry_until(max_attempts: 5, sleep_interval: 5) do
            mr_widget.has_pipeline_status?('passed')
          end
          expect(mr_widget).to have_content('Test coverage 66.67%')
        end
      end
    end

    private

    def configure_code_coverage(coverage_tool_pattern)
      Page::Project::Menu.perform(&:go_to_ci_cd_settings)
      Page::Project::Settings::CICD.perform do |settings|
        settings.expand_general_pipelines do |coverage|
          coverage.configure_coverage_regex(coverage_tool_pattern)
        end
      end
    end
  end
end
