# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', feature_category: :wiki do
    describe 'A project wiki' do
      let(:initial_wiki) { create(:project_wiki_page) }
      let(:new_path) { "a/new/path-with-spaces" }

      before do
        Flow::Login.sign_in
      end

      it 'can change the directory path of a page' do
        initial_wiki.visit!

        Page::Project::Wiki::Show.perform(&:click_edit)

        Page::Project::Wiki::Edit.perform do |edit|
          edit.set_path("#{new_path}/home")
          edit.click_submit
          edit.set_message('changing the path of the home page')
          edit.confirm_message
        end

        Page::Project::Wiki::Show.perform do |wiki|
          wiki.expand_sidebar_if_collapsed
          expect(wiki).to have_directory('a')
          expect(wiki).to have_directory('new')
          expect(wiki).to have_directory('path with spaces')
        end
      end
    end
  end
end
