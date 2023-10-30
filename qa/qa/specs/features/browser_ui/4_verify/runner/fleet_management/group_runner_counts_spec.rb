# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :runner do
    describe 'Runner fleet management' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:description) { "test-runner-#{Time.now.to_i}" }

      let!(:runner) do
        Resource::GroupRunner.fabricate! do |runner|
          runner.name = executor
          runner.description = description
        end
      end

      after do
        runner.remove_via_api!
      end

      it(
        'shows group runner counts', :reliable,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/421256'
      ) do
        Flow::Login.sign_in

        runner.group.visit!

        Page::Group::Menu.perform(&:go_to_runners)
        group_runners = Page::Group::Runners::Index.perform(&:count_group_runners)
        project_runners = Page::Group::Runners::Index.perform(&:count_project_runners)
        all_runners = Page::Group::Runners::Index.perform(&:count_all_runners)

        aggregate_failures do
          expect(group_runners).to eq(1)
          expect(project_runners).to eq(0)
          expect(all_runners).to be >= 1
        end
      end
    end
  end
end
