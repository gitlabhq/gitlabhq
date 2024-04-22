# frozen_string_literal: true

module QA
  RSpec.describe 'Configure' do
    describe 'AutoDevOps Templates', only: { subdomain: %i[staging staging-canary] }, product_group: :environments,
      quarantine: {
        issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/432409',
        type: :test_environment
      } do
      using RSpec::Parameterized::TableSyntax

      # specify jobs to be disabled in the pipeline.
      # CANARY_ENABLED will allow the pipeline to be
      # blocked by a manual job, rather than fail
      # during the production run
      let(:optional_jobs) do
        %w[
          SAST_DISABLED DAST_DISABLED
          DEPENDENCY_SCANNING_DISABLED
          CONTAINER_SCANNING_DISABLED
          CANARY_ENABLED
        ]
      end

      where(:case_name, :template, :testcase) do
        'using express template' | 'express' | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348075'
      end

      with_them do
        let!(:project) do
          create(:project,
            :auto_devops,
            name: "#{template}-autodevops-project-template",
            template_name: template,
            description: "Let's see if the #{template} project works")
        end

        let(:pipeline) do
          create(:pipeline,
            project: project,
            variables: optional_jobs.map do |job|
              { key: job, value: '1', variable_type: 'env_var' }
            end)
        end

        before do
          Flow::Login.sign_in
        end

        it 'works with Auto DevOps', testcase: params[:testcase] do
          %w[build code_quality test].each do |job|
            pipeline.visit!

            Page::Project::Pipeline::Show.perform do |show_page|
              show_page.click_job(job)
            end

            Page::Project::Job::Show.perform do |show|
              expect(show).to have_passed(timeout: 800)
            end
          end
        end
      end
    end
  end
end
