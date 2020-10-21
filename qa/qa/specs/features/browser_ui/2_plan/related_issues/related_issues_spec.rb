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

      it 'relates and unrelates one issue to/from another', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/541' do
        issue_1.visit!

        Page::Project::Issue::Show.perform do |show|
          max_wait = 60

          show.relate_issue(issue_2)

          expect(show.related_issuable_item).to have_text(issue_2.title, wait: max_wait)

          show.click_remove_related_issue_button

          expect(show).to have_no_text(issue_2.title, wait: max_wait)
        end
      end
    end
  end
end
