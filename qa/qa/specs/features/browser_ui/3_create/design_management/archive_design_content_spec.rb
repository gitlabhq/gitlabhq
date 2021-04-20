# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Design Management' do
      let(:first_design) { Resource::Design.fabricate! }

      let(:second_design) do
        Resource::Design.fabricate! do |design|
          design.issue = first_design.issue
          design.filename = 'values.png'
        end
      end

      let(:third_design) do
        Resource::Design.fabricate! do |design|
          design.issue = second_design.issue
          design.filename = 'testfile.png'
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'user archives a design', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1761' do
        third_design.issue.visit!

        Page::Project::Issue::Show.perform do |issue|
          issue.select_design(third_design.filename)

          issue.archive_selected_designs

          expect(issue).not_to have_design(third_design.filename)
          expect(issue).to have_design(first_design.filename)
          expect(issue).to have_design(second_design.filename)
        end

        Page::Project::Issue::Show.perform do |issue|
          issue.select_design(second_design.filename)
          issue.select_design(first_design.filename)

          issue.archive_selected_designs

          expect(issue).not_to have_design(first_design.filename)
          expect(issue).not_to have_design(second_design.filename)
        end
      end
    end
  end
end
