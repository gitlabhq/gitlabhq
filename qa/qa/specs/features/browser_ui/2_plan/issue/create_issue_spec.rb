# frozen_string_literal: true

module QA
  context :plan, :smoke do
    describe 'Issue creation' do
      let(:issue_title) { 'issue title' }

      it 'user creates an issue' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        Factory::Resource::Issue.fabricate! do |issue|
          issue.title = issue_title
        end

        Page::Menu::Side.act { click_issues }

        expect(page).to have_content(issue_title)
      end
    end
  end
end
