# frozen_string_literal: true

module QA
  RSpec.shared_context 'merge train spec with user prep' do
    let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
    let(:file_name) { Faker::Lorem.word }
    let(:mr_title) { Faker::Lorem.sentence }
    let(:admin_api_client) { Runtime::API::Client.as_admin }

    let(:user) do
      Resource::User.fabricate_via_api! do |user|
        user.api_client = admin_api_client
      end
    end

    let(:project) do
      Resource::Project.fabricate_via_api! do |project|
        project.name = 'pipeline-for-merge-trains'
      end
    end

    let!(:runner) do
      Resource::ProjectRunner.fabricate! do |runner|
        runner.project = project
        runner.name = executor
        runner.tags = [executor]
      end
    end

    let!(:project_files) do
      Resource::Repository::Commit.fabricate_via_api! do |commit|
        commit.project = project
        commit.commit_message = 'Add .gitlab-ci.yml'
        commit.add_files(
          [
            {
              file_path: '.gitlab-ci.yml',
              content: <<~YAML
                  test_merge_train:
                    tags:
                      - #{executor}
                    script:
                      - sleep 10
                      - echo 'OK!'
                    only:
                      - merge_requests
              YAML
            },
            {
              file_path: file_name,
              content: Faker::Lorem.sentence
            }
          ]
        )
      end
    end

    before do
      project.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

      Flow::Login.sign_in
      project.visit!
      Flow::MergeRequest.enable_merge_trains

      Flow::Login.sign_in(as: user)

      Resource::MergeRequest.fabricate_via_api! do |merge_request|
        merge_request.title = mr_title
        merge_request.project = project
        merge_request.description = Faker::Lorem.sentence
        merge_request.target_new_branch = false
        merge_request.update_existing_file = true
        merge_request.file_name = file_name
        merge_request.file_content = Faker::Lorem.sentence
      end.visit!

      Page::MergeRequest::Show.perform do |show|
        show.has_pipeline_status?('passed')
        show.try_to_merge!
      end
    end

    after do
      runner&.remove_via_api!
      user&.remove_via_api!
    end
  end
end
