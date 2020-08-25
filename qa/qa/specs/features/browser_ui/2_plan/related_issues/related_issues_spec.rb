# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    describe 'Related issues' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-to-test-related-issues'
        end
      end

      let(:issue_1) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
        end
      end

      let(:issue_2) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'relates and unrelates one issue to/from another' do
        issue_1.visit!

        Page::Project::Issue::Show.perform do |show|
          max_wait = 60
          wait_interval = 1

          show.relate_issue(issue_2)

          show.wait_until(reload: false, max_duration: max_wait, sleep_interval: wait_interval) do
            expect(show.related_issuable_item).to have_content(issue_2.title)
          end

          show.click_remove_related_issue_button

          show.wait_until(reload: false, max_duration: max_wait, sleep_interval: wait_interval) do
            expect(show).not_to have_content(issue_2.title)
          end
        end
      end
    end
  end
end
