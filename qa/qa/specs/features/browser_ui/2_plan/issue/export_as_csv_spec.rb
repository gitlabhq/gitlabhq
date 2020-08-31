# frozen_string_literal: true

require 'securerandom'

module QA
  RSpec.describe 'Plan', :reliable do
    describe 'Issues list' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-to-test-export-issues-as-csv'
        end
      end

      before do
        Flow::Login.sign_in

        2.times do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.project = project
          end
        end

        project.visit!
        Page::Project::Menu.perform(&:click_issues)
      end

      it 'successfully exports issues list as CSV', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/764' do
        Page::Project::Issue::Index.perform do |index|
          index.click_export_as_csv_button

          expect(index.export_issues_modal).to have_content('2 issues selected')

          index.click_export_issues_button

          expect(index).to have_content(/Your CSV export has started. It will be emailed to (\S+) when complete./)
        end
      end
    end
  end
end
