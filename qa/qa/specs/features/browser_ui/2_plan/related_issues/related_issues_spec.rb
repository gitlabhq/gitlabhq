# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke, product_group: :project_management do
    describe 'Related issues' do
      let(:project) { create(:project, name: 'project-to-test-related-issues') }
      let(:issues) { create_list(:issue, 2, project: project) }

      before do
        Flow::Login.sign_in
      end

      it 'relates and unrelates one issue to/from another', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347994' do
        issues.first.visit!

        Page::Project::Issue::Show.perform do |show|
          max_wait = 60

          show.relate_issue(issues.last)

          expect(show.related_issuable_item).to have_text(issues.last.title, wait: max_wait)

          show.click_remove_related_issue_button

          expect(show).not_to have_text(issues.last.title, wait: max_wait)
        end
      end
    end
  end
end
