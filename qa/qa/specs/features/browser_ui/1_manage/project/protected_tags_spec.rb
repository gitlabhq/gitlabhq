# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    # TODO: Remove :requires_admin meta when the `Runtime::Feature.enable` method call is removed
    describe 'Repository tags', :requires_admin do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-for-tags'
          project.initialize_with_readme = true
        end
      end

      before do
        Runtime::Feature.enable(:invite_members_group_modal, project: project)
      end

      let(:developer_user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:maintainer_user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2) }
      let(:tag_name) { 'v0.0.1' }
      let(:tag_message) { 'Version 0.0.1' }
      let(:tag_release_notes) { 'Release It!' }

      shared_examples 'successful tag creation' do |user|
        it "can be created by #{user}" do
          Flow::Login.sign_in(as: send(user))

          create_tag_for_project(project, tag_name, tag_message, tag_release_notes)

          Page::Project::Tag::Show.perform do |show|
            expect(show).to have_tag_name(tag_name)
            expect(show).to have_tag_message(tag_message)
            expect(show).to have_tag_release_notes(tag_release_notes)
            expect(show).not_to have_element(:create_tag_button)
          end
        end
      end

      shared_examples 'unsuccessful tag creation' do |user|
        it "cannot be created by an unauthorized #{user}" do
          Flow::Login.sign_in(as: send(user))

          create_tag_for_project(project, tag_name, tag_message, tag_release_notes)

          Page::Project::Tag::New.perform do |new_tag|
            expect(new_tag).to have_content('You are not allowed to create this tag as it is protected.')
            expect(new_tag).to have_element(:create_tag_button)
          end
        end
      end

      context 'when not protected' do
        before do
          add_members_to_project(project)
        end

        it_behaves_like 'successful tag creation', :developer_user
        it_behaves_like 'successful tag creation', :maintainer_user
      end

      context 'when protected' do
        before do
          add_members_to_project(project)

          Flow::Login.sign_in

          protect_tag_for_project(project, 'v*', 'Maintainers')

          Page::Main::Menu.perform(&:sign_out)
        end

        it_behaves_like 'unsuccessful tag creation', :developer_user
        it_behaves_like 'successful tag creation', :maintainer_user
      end

      def create_tag_for_project(project, name, message, release_notes)
        project.visit!

        Page::Project::Menu.perform(&:go_to_repository_tags)
        Page::Project::Tag::Index.perform(&:click_new_tag_button)

        Page::Project::Tag::New.perform do |new_tag|
          new_tag.fill_tag_name(name)
          new_tag.fill_tag_message(message)
          new_tag.fill_release_notes(release_notes)
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
        @developer_user = developer_user
        @maintainer_user = maintainer_user

        project.add_member(@developer_user, Resource::Members::AccessLevel::DEVELOPER)
        project.add_member(@maintainer_user, Resource::Members::AccessLevel::MAINTAINER)
      end
    end
  end
end
