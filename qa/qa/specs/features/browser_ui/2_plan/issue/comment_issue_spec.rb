# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke, product_group: :project_management do
    describe 'Issue comments' do
      before do
        Flow::Login.sign_in

        create(:issue).visit!
      end

      it 'comments on an issue and edits the comment', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347978' do
        Page::Project::Issue::Show.perform do |show|
          first_version_of_comment = 'First version of the comment'
          second_version_of_comment = 'Second version of the comment'

          show.comment(first_version_of_comment)

          expect(show).to have_comment(first_version_of_comment)

          show.edit_comment(second_version_of_comment)

          expect(show).to have_comment(second_version_of_comment)
          expect(show).not_to have_content(first_version_of_comment)
        end
      end
    end
  end
end
