# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Design management' do
      let(:issue) { Resource::Issue.fabricate_via_api! }
      let(:design_filename) { 'banana_sample.gif' }
      let(:design) { File.absolute_path(File.join('spec', 'fixtures', design_filename)) }
      let(:annotation) { "This design is great!" }

      before do
        Flow::Login.sign_in
      end

      it 'user adds a design and annotation' do
        issue.visit!

        Page::Project::Issue::Show.perform do |show|
          show.click_designs_tab
          show.add_design(design)
          show.click_design(design_filename)
          show.add_annotation(annotation)

          expect(show).to have_annotation(annotation)

          show.click_discussion_tab
        end
      end
    end
  end
end
