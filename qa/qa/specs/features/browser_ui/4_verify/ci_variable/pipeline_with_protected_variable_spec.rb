# frozen_string_literal: true

require 'faker'

module QA
  RSpec.describe 'Verify', :runner do
    describe 'Pipeline with protected variable' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(8)}" }
      let(:protected_value) { Faker::Alphanumeric.alphanumeric(8) }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-ci-variables'
          project.description = 'project with CI variables'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let!(:ci_file) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  job:
                    tags:
                      - #{executor}
                    script: echo $PROTECTED_VARIABLE
                YAML
              }
            ]
          )
        end
      end

      let(:developer) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      let(:maintainer) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2)
      end

      before do
        Flow::Login.sign_in
        project.visit!
        project.add_member(developer)
        project.add_member(maintainer, Resource::Members::AccessLevel::MAINTAINER)
        add_ci_variable
      end

      after do
        runner.remove_via_api!
      end

      it 'exposes variable on protected branch', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/156' do
        create_protected_branch

        [developer, maintainer].each do |user|
          user_commit_to_protected_branch(Runtime::API::Client.new(:gitlab, user: user))
          go_to_pipeline_job(user)

          Page::Project::Job::Show.perform do |show|
            expect(show.output).to have_content(protected_value), 'Expect protected variable to be in job log.'
          end
        end
      end

      it 'does not expose variable on unprotected branch', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/156' do
        [developer, maintainer].each do |user|
          create_merge_request(Runtime::API::Client.new(:gitlab, user: user))
          go_to_pipeline_job(user)

          Page::Project::Job::Show.perform do |show|
            expect(show.output).to have_no_content(protected_value), 'Expect protected variable to NOT be in job log.'
          end
        end
      end

      private

      def add_ci_variable
        Resource::CiVariable.fabricate_via_api! do |ci_variable|
          ci_variable.project = project
          ci_variable.key = 'PROTECTED_VARIABLE'
          ci_variable.value = protected_value
          ci_variable.protected = true
        end
      end

      def create_protected_branch
        # Using default setups, which allows access for developer and maintainer
        Resource::ProtectedBranch.fabricate_via_api! do |resource|
          resource.branch_name = 'protected-branch'
          resource.project = project
        end
      end

      def user_commit_to_protected_branch(api_client)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.api_client = api_client
          commit.project = project
          commit.branch = 'protected-branch'
          commit.commit_message = Faker::Lorem.sentence
          commit.add_files(
            [
              {
                file_path: Faker::File.unique.file_name,
                content: Faker::Lorem.sentence
              }
            ]
          )
        end
      end

      def create_merge_request(api_client)
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.api_client = api_client
          merge_request.project = project
          merge_request.description = Faker::Lorem.sentence
          merge_request.target_new_branch = false
          merge_request.file_name = Faker::File.unique.file_name
          merge_request.file_content = Faker::Lorem.sentence
        end
      end

      def go_to_pipeline_job(user)
        Flow::Login.sign_in(as: user)
        project.visit!
        Flow::Pipeline.visit_latest_pipeline(pipeline_condition: 'completed')

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('job')
        end
      end
    end
  end
end
