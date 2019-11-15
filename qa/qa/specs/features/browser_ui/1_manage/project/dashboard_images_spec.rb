# frozen_string_literal: true

require 'nokogiri'

module QA
  context 'Manage' do
    describe 'Check for broken images', :requires_admin do
      before(:context) do
        admin = QA::Resource::User.new.tap do |user|
          user.username = QA::Runtime::User.admin_username
          user.password = QA::Runtime::User.admin_password
        end
        @api_client = Runtime::API::Client.new(:gitlab, user: admin)
        @new_user = Resource::User.fabricate_via_api! do |user|
          user.api_client = @api_client
        end
        @new_admin = Resource::User.fabricate_via_api! do |user|
          user.admin = true
          user.api_client = @api_client
        end

        Page::Main::Menu.perform(&:sign_out_if_signed_in)
      end

      after(:context) do
        @new_user.remove_via_api!
        @new_admin.remove_via_api!
      end

      shared_examples 'loads all images' do
        it 'loads all images' do
          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          Page::Main::Login.perform { |login| login.sign_in_using_credentials(user: new_user) }

          Page::Dashboard::Welcome.perform do |welcome|
            expect(welcome).to have_welcome_title("Welcome to GitLab")

            # This would be better if it were a visual validation test
            expect(welcome).to have_loaded_all_images
          end
        end
      end

      context 'when logged in as a new user' do
        it_behaves_like 'loads all images' do
          let(:new_user) { @new_user }
        end
      end

      context 'when logged in as a new admin' do
        it_behaves_like 'loads all images' do
          let(:new_user) { @new_admin }
        end
      end
    end
  end
end
