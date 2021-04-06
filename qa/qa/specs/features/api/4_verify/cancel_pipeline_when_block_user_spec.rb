# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :requires_admin do
    describe 'When user is blocked' do
      let!(:admin_api_client) { Runtime::API::Client.as_admin }
      let!(:user_api_client) { Runtime::API::Client.new(:gitlab, user: user) }

      let(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = admin_api_client
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-for-canceled-schedule'
        end
      end

      before do
        project.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        Resource::PipelineSchedules.fabricate_via_api! do |schedule|
          schedule.api_client = user_api_client
          schedule.project = project
        end

        Support::Waiter.wait_until { !pipeline_schedule[:id].nil? && pipeline_schedule[:active] == true }
      end

      after do
        user.remove_via_api!
        project.remove_via_api!
      end

      it 'pipeline schedule is canceled', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1730' do
        user.block!

        expect(pipeline_schedule[:active]).not_to be_truthy, "Expected schedule active state to be false - active state #{pipeline_schedule[:active]}"
      end

      private

      def pipeline_schedule
        project.pipeline_schedules.first
      end
    end
  end
end
