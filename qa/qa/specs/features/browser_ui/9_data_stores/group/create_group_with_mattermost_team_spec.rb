# frozen_string_literal: true

module QA
  RSpec.describe 'Configure', :orchestrated, :mattermost, product_group: :tenant_scale do
    describe 'Mattermost support' do
      it 'user creates a group with a mattermost team',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347890' do
        Flow::Login.sign_in
        Page::Main::Menu.perform(&:go_to_groups)

        Page::Dashboard::Groups.perform do |groups|
          groups.click_new_group

          Page::Group::New.perform do |group_new|
            group_new.click_create_group

            expect(group_new).to have_content(
              /Create a Mattermost team for this group/
            )
          end
        end
      end
    end
  end
end
