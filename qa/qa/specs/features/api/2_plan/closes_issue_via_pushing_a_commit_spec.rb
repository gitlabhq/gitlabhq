# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    include Support::API

    describe 'Issue', product_group: :project_management do
      let(:issue) { create(:issue, project: create(:project, :with_readme)) }

      it 'closes via pushing a commit',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347947' do
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.commit_message = "Closes ##{issue.iid}"
          push.new_branch = false
          push.file_content = "Closes ##{issue.iid}"
          push.project = issue.project
        end

        expect { issue.reload!.state }.to eventually_eq('closed').within(max_duration: 10, sleep_interval: 1)
      end
    end
  end
end
