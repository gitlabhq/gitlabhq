# frozen_string_literal: true

require 'airborne'
require 'securerandom'
require 'digest'

module QA
  RSpec.describe 'Create' do
    describe 'Compare archives of different user projects with the same name and check they\'re different' do
      include Support::Api
      let(:project_name) { "project-archive-download-#{SecureRandom.hex(8)}" }

      let(:archive_types) { %w(tar.gz tar.bz2 tar zip) }

      let(:users) do
        {
          user1: { username: Runtime::Env.gitlab_qa_username_1, password: Runtime::Env.gitlab_qa_password_1 },
          user2: { username: Runtime::Env.gitlab_qa_username_2, password: Runtime::Env.gitlab_qa_password_2 }
        }
      end

      before do
        users.each do |_, user_info|
          user_info[:user] = Resource::User.fabricate_or_use(user_info[:username], user_info[:password])
          user_info[:api_client] = Runtime::API::Client.new(:gitlab, user: user_info[:user])
          user_info[:api_client].personal_access_token
          user_info[:project] = create_project(user_info[:user], user_info[:api_client], project_name)
        end
      end

      it 'download archives of each user project then check they are different', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/427' do
        archive_checksums = {}

        users.each do |user_key, user_info|
          archive_checksums[user_key] = {}

          archive_types.each do |type|
            archive_path = download_project_archive_via_api(user_info[:api_client], user_info[:project], type).path
            archive_checksums[user_key][type] = Digest::MD5.hexdigest(File.read(archive_path))
          end
        end

        QA::Runtime::Logger.debug("Archive checksums are #{archive_checksums}")

        expect(archive_checksums[:user1]).not_to include(archive_checksums[:user2])
      end

      def create_project(user, api_client, project_name)
        project = Resource::Project.fabricate_via_api! do |project|
          project.standalone = true
          project.add_name_uuid = false
          project.name = project_name
          project.path_with_namespace = "#{user.username}/#{project_name}"
          project.api_client = api_client
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
          push.user = user
        end

        project
      end

      def download_project_archive_via_api(api_client, project, type = 'tar.gz')
        get_project_archive_zip = Runtime::API::Request.new(api_client, project.api_get_archive_path(type))
        project_archive_download = get(get_project_archive_zip.url, raw_response: true)
        expect(project_archive_download.code).to eq(200)

        project_archive_download.file
      end
    end
  end
end
