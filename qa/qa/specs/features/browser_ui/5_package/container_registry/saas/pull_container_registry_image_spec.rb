# frozen_string_literal: true

module QA
  RSpec.describe 'Package' do
    describe 'SaaS Container Registry', :smoke,
      only: { subdomain: :staging }, product_group: :container_registry do
      before do
        Flow::Login.sign_in
      end

      it 'pulls an image from an existing repository',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412799',
        quarantine: {
          type: :test_environment,
          issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/435585"
        } do
        project = build(:project, path_with_namespace: 'gitlab-qa/container-registry-sanity').reload!
        project.visit!

        Page::Project::Menu.perform(&:go_to_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)
        Page::Project::Pipeline::New.perform(&:click_run_pipeline_button)

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('test')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end
      end
    end
  end
end
