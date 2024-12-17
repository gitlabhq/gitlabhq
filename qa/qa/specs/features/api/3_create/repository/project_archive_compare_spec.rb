# frozen_string_literal: true

require 'digest'

module QA
  RSpec.describe 'Create', :requires_admin, product_group: :source_code do
    describe 'Compare archives of different user projects with the same name and check they\'re different' do
      include Support::API

      let(:project_name) { "project-archive-download" }
      let(:archive_types) { %w[tar.gz tar.bz2 tar zip] }

      let(:users) do
        create_list(:user, 2, :with_personal_access_token).each_with_index.to_h do |user, index|
          [
            :"user_#{index + 1}",
            {
              user: user,
              api_client: user.api_client,
              project: create_project(user, user.api_client, project_name)
            }
          ]
        end
      end

      it 'download archives of each user project then check they are different',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347748' do
        archive_checksums = {}

        users.each do |user_key, user_info|
          archive_checksums[user_key] = {}

          archive_types.each do |type|
            archive_path = download_project_archive_via_api(user_info[:api_client], user_info[:project], type).path
            archive_checksums[user_key][type] = Digest::MD5.hexdigest(File.read(archive_path))
          end
        end

        QA::Runtime::Logger.debug("Archive checksums are #{archive_checksums}")

        expect(archive_checksums[:user_1]).not_to include(archive_checksums[:user_2])
      end

      def create_project(user, api_client, project_name)
        project = create(:project, name: project_name, api_client: api_client, add_name_uuid: false,
          personal_namespace: user.username)

        create(:commit, project: project, api_client: api_client, commit_message: 'Add README.md', actions: [
          { action: 'create', file_path: 'README.md', content: '# This is a test project' }
        ])

        project
      end

      def download_project_archive_via_api(api_client, project, type = 'tar.gz')
        get_project_archive_zip = Runtime::API::Request.new(api_client, project.api_get_archive_path(type))
        project_archive_download = Support::API.get(get_project_archive_zip.url, raw_response: true)
        expect(project_archive_download.code).to eq(Support::API::HTTP_STATUS_OK)

        project_archive_download.file
      end
    end
  end
end
