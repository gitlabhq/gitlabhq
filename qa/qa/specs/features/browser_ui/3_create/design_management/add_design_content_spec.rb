# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Design Management' do
      let(:issue) { Resource::Issue.fabricate_via_api! }
      let(:design_filename) { 'banana_sample.gif' }
      let(:design) { File.absolute_path(File.join('qa', 'fixtures', 'designs', design_filename)) }
      let(:annotation) { "This design is great!" }

      before do
        Flow::Login.sign_in
      end

      it 'user adds a design and annotates it', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/955' do
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
