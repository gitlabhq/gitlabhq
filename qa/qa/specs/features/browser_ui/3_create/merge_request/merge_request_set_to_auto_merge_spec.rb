# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :runner, product_group: :code_review do
    describe 'Merge request set to auto-merge' do
      let(:runner_name) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:project) { create(:project, name: 'set-to-auto-merge') }
      let!(:runner) { create(:project_runner, project: project, name: runner_name, tags: [runner_name]) }

      let!(:ci_file) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              test:
                tags: ["#{runner_name}"]
                script: sleep 25
                only:
                  - merge_requests
            YAML
          }
        ])
      end

      before do
        Flow::Login.sign_in
      end

      after do
        runner&.remove_via_api!
      end

      it 'merges after pipeline succeeds',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347686' do
        merge_request = create(:merge_request, project: project)

        merge_request.visit!

        Page::MergeRequest::Show.perform do |mr|
          mr.set_to_auto_merge!

          aggregate_failures do
            expect { mr.merged? }.to eventually_be_truthy.within(max_duration: 120),
              "Expected content 'The changes were merged' but it did not appear."
            expect(merge_request.reload!.state).to eq('merged')
            expect(project.pipelines.last[:status]).to eq('success')
          end
        end
      end
    end
  end
end
