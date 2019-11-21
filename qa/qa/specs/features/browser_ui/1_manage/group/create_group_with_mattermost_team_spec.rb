# frozen_string_literal: true

module QA
  context 'Configure', :orchestrated, :mattermost do
    describe 'Mattermost support' do
      it 'user creates a group with a mattermost team' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
        Page::Main::Menu.perform(&:go_to_groups)

        Page::Dashboard::Groups.perform do |groups|
          groups.click_new_group

          expect(groups).to have_content(
            /Create a Mattermost team for this group/
          )
        end
      end
    end
  end
end
