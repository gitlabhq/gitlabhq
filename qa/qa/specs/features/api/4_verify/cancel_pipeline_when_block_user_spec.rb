# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :requires_admin, product_group: :pipeline_execution do
    describe 'When user is blocked' do
      let(:user) { create(:user).tap(&:create_personal_access_token!) }
      let(:admin_user) { Runtime::User::Store.admin_user }

      let(:project) { create(:project, name: 'project-for-canceled-schedule') }
      let(:ref) { 'master' }

      before do
        project.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
        project.create_repository_branch(ref)

        # Retry is needed due to delays with project authorization updates
        # Long term solution to accessing the status of a project authorization update
        # has been proposed in https://gitlab.com/gitlab-org/gitlab/-/issues/393369
        Support::Retrier.retry_on_exception(max_attempts: 60, sleep_interval: 1) do
          create(:pipeline_schedule, ref: ref, api_client: user.api_client, project: project)
        end

        Support::Waiter.wait_until { !pipeline_schedule[:id].nil? && pipeline_schedule[:active] == true }
      end

      it 'pipeline schedule is canceled',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347999' do
        admin_user.block!(user.id)

        expect(pipeline_schedule[:active]).not_to be_truthy,
          "Expected schedule active state to be false - active state #{pipeline_schedule[:active]}"
      end

      private

      def pipeline_schedule
        project.pipeline_schedules.first
      end
    end
  end
end
