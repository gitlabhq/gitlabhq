# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'promote issue to epic' do
      let(:issue_title) { "My Awesome Issue #{SecureRandom.hex(8)}" }

      it 'user promotes issue to an epic' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        group = Resource::Group.fabricate_via_api!

        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'promote-issue-to-epic'
          project.description = 'Project to promote issue to epic'
          project.group = group
        end

        Resource::Issue.fabricate_via_browser_ui! do |issue|
          issue.title = issue_title
          issue.project = project
        end

        Page::Project::Issue::Show.perform do |show|
          # Due to the randomness of tests execution, sometimes a previous test
          # may have changed the filter, which makes the below action needed.
          # TODO: Make this test completely independent, not requiring the below step.
          show.select_all_activities_filter
          # We add a space together with the '/promote' string to avoid test flakiness
          # due to the tooltip '/promote Promote issue to an epic (may expose
          # confidential information)' from being shown, which may cause the click not
          # to work properly.
          show.comment('/promote ')
        end

        group.visit!
        QA::EE::Page::Group::Menu.perform(&:click_group_epics_link)
        QA::EE::Page::Group::Epic::Index.perform do |index|
          index.click_first_epic(QA::EE::Page::Group::Epic::Show)
        end

        expect(page).to have_content(issue_title)
        expect(page).to have_content(/promoted from issue .* \(closed\)/)
      end
    end
  end
end
