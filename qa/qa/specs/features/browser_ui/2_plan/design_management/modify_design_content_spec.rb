# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :product_planning do
    describe 'Design Management' do
      let(:design) do
        Resource::Design.fabricate_via_browser_ui! do |design|
          design.filename = 'testfile.png'
        end
      end

      before do
        Flow::Login.sign_in
      end

      it(
        'user adds a design and modifies it',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347712'
      ) do
        design.issue.visit!

        Page::Project::Issue::Show.perform do |issue|
          expect(issue).to have_created_icon
        end

        Page::Project::Issue::Show.perform do |issue|
          issue.update_design(design.filename)
          expect(issue).to have_modified_icon
        end
      end
    end
  end
end
