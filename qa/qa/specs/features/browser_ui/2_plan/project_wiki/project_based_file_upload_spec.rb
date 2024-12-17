# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :knowledge do
    describe 'Testing project wiki file upload' do
      let(:initial_wiki) { create(:project_wiki_page) }
      let(:page_title) { 'Content Editor Page' }
      let(:heading_text) { 'My New Heading' }
      let(:image_file_name) { 'testfile.png' }

      before do
        Flow::Login.sign_in
      end

      it 'by creating a formatted page with an image uploaded',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347640' do
        initial_wiki.visit!

        Page::Project::Wiki::Show.perform(&:click_new_page)

        Page::Project::Wiki::Edit.perform do |edit|
          edit.set_title(page_title)
          edit.use_new_editor
          edit.add_heading('Heading 1', heading_text)
          edit.upload_image(Runtime::Path.fixture('designs', image_file_name))
        end

        Page::Project::Wiki::Edit.perform(&:click_submit)

        Page::Project::Wiki::Show.perform do |wiki|
          aggregate_failures 'page shows expected content' do
            expect(wiki).to have_title(page_title)
            expect(wiki).to have_heading('h1', heading_text)
            expect(wiki).to have_image(image_file_name)
          end
        end
      end
    end
  end
end
