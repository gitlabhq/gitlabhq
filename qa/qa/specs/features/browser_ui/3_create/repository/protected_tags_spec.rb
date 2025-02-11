# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Repository tags', :requires_admin, product_group: :source_code do
      let(:project) { create(:project, :with_readme, name: 'project-for-tags') }
      let(:developer_user) { create(:user) }
      let(:maintainer_user) { create(:user) }

      let(:tag_name) { 'v0.0.1' }
      let(:tag_message) { 'Version 0.0.1' }

      shared_examples 'successful tag creation' do |user, testcase|
        it "can be created by #{user}", testcase: testcase do
          Flow::Login.sign_in(as: send(user))

          create_tag_for_project(project, tag_name, tag_message)

          Page::Project::Tag::Show.perform do |show|
            expect(show).to have_tag_name(tag_name)
            expect(show).to have_tag_message(tag_message)
            expect(show).not_to have_element('create-tag-button')
          end
        end
      end

      shared_examples 'unsuccessful tag creation' do |user, testcase|
        it "cannot be created by an unauthorized #{user}", testcase: testcase do
          Flow::Login.sign_in(as: send(user))

          create_tag_for_project(project, tag_name, tag_message)

          Page::Project::Tag::New.perform do |new_tag|
            expect(new_tag).to have_content('You are not allowed to create this tag as it is protected.')
            expect(new_tag).to have_element('data-testid': 'create-tag-button')
          end
        end
      end

      context 'when not protected' do
        before do
          add_members_to_project(project)
        end

        it_behaves_like 'successful tag creation', :developer_user, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347930'
        it_behaves_like 'successful tag creation', :maintainer_user, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347929'
      end

      context 'when protected' do
        before do
          add_members_to_project(project)

          Flow::Login.sign_in

          protect_tag_for_project(project, 'v*', 'Maintainers')

          Page::Main::Menu.perform(&:sign_out)
        end

        it_behaves_like 'unsuccessful tag creation', :developer_user, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347927'
        it_behaves_like 'successful tag creation', :maintainer_user, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347928'
      end

      def create_tag_for_project(project, name, message)
        project.visit!

        Page::Project::Menu.perform(&:go_to_repository_tags)
        Page::Project::Tag::Index.perform(&:click_new_tag_button)

        Page::Project::Tag::New.perform do |new_tag|
          new_tag.fill_tag_name(name)
          new_tag.fill_tag_message(message)
          new_tag.click_create_tag_button
        end
      end

      def protect_tag_for_project(project, tag, role)
        project.visit!

        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_protected_tags do |protected_tags|
            protected_tags.set_tag(tag)
            protected_tags.choose_access_level_role(role)

            protected_tags.click_protect_tag_button
          end
        end
      end

      def add_members_to_project(project)
        project.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
        project.add_member(maintainer_user, Resource::Members::AccessLevel::MAINTAINER)
      end
    end
  end
end
