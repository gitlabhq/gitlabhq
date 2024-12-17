# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :product_planning do
    describe 'Design Management' do
      let(:design_filename) { 'banana_sample.gif' }
      let(:design) { Runtime::Path.fixture('designs', design_filename) }
      let(:annotation) { "This design is great!" }

      let(:issue) do
        create(
          :issue,
          project: create(:project, group: create(:group, path: "design-management-#{SecureRandom.hex(4)}"))
        )
      end

      before do
        Flow::Login.sign_in
      end

      it 'user adds a design and annotates it',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347822' do
        issue.visit!

        Page::Project::Issue::Show.perform do |issue|
          issue.add_design(design)
          issue.click_design(design_filename)
          issue.add_annotation(annotation)

          expect(issue).to have_annotation(annotation)
        end
      end
    end
  end
end
