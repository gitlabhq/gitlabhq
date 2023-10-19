# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :knowledge do
    describe 'Project Wiki' do
      let(:small_number_of_pages) { 5 }
      let(:large_number_of_pages) { 15 }
      let(:random_page) { "bulk_#{rand(0..4)}" }

      let(:small_wiki) { create_wiki_pages small_number_of_pages }
      let(:large_wiki) { create_wiki_pages large_number_of_pages }

      before do
        Flow::Login.sign_in
      end

      context 'with Wiki Sidebar' do
        it 'has all expected links that work',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347814' do
          small_wiki.visit!

          small_number_of_pages.times do |index|
            Page::Project::Wiki::Show.perform do |list|
              expect(list).to have_page_listed "bulk_#{index}"
            end
          end

          Page::Project::Wiki::Show.perform do |list|
            list.click_page_link random_page
          end

          Page::Project::Wiki::Show.perform do |wiki|
            expect(wiki).to have_title random_page
          end
        end
      end

      context 'with Wiki Page List' do
        it 'has all expected links that work',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347813' do
          large_wiki.visit!

          Page::Project::Wiki::Show.perform(&:click_view_all_pages)

          large_number_of_pages.times do |index|
            Page::Project::Wiki::List.perform do |list|
              expect(list).to have_page_listed "bulk_#{index}"
            end
          end

          Page::Project::Wiki::List.perform do |list|
            list.click_page_link random_page
          end

          Page::Project::Wiki::Show.perform do |wiki|
            expect(wiki).to have_title random_page
          end
        end
      end

      private

      def create_wiki_pages(no_of_pages)
        wiki = create(:project_wiki_page)
        no_of_pages.times do |index|
          create(:project_wiki_page, title: "bulk_#{index}", project: wiki.project)
        end
        wiki
      end
    end
  end
end
