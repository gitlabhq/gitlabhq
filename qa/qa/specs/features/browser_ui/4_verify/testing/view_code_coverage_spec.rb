# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe 'Code coverage statistics' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:runner) do
        Resource::ProjectRunner.fabricate_via_api! do |runner|
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
              coverage: '/\\d+\\.\\d+% covered/'
              script:
                - echo '66.67% covered'
          EOF
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
      end

      it 'creates an MR with code coverage statistics', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348068' do
        merge_request.visit!

        Page::MergeRequest::Show.perform do |mr_widget|
          mr_widget.has_pipeline_status?('passed')
          expect(mr_widget).to have_content('Test coverage 66.67%')
        end
      end
    end
  end
end
