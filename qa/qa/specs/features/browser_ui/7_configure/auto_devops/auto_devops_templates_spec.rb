# frozen_string_literal: true

module QA
  RSpec.describe 'Configure' do
    describe 'AutoDevOps Templates', only: { subdomain: :staging } do
      # specify jobs to be disabled in the pipeline.
      # CANARY_ENABLED will allow the pipeline to be
      # blocked by a manual job, rather than fail
      # during the production run
      let(:optional_jobs) do
        %w[
          LICENSE_MANAGEMENT_DISABLED
          SAST_DISABLED DAST_DISABLED
          DEPENDENCY_SCANNING_DISABLED
          CONTAINER_SCANNING_DISABLED
          CANARY_ENABLED
        ]
      end

      where(:template) do
        %w[express]
      end

      with_them do
        let!(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = "#{template}-autodevops-project-template"
            project.template_name = template
            project.description = "Let's see if the #{template} project works..."
            project.auto_devops_enabled = true
          end
        end

        let(:pipeline) do
          Resource::Pipeline.fabricate_via_api! do |pipeline|
            pipeline.project = project
            pipeline.variables =
              optional_jobs.map do |job|
                { key: job, value: '1', variable_type: 'env_var' }
              end
          end
        end

        before do
          Flow::Login.sign_in
        end

        it 'works with Auto DevOps' do
          %w[build code_quality test].each do |job|
            pipeline.visit!

            Page::Project::Pipeline::Show.perform do |show_page|
              show_page.click_job(job)
            end

            Page::Project::Job::Show.perform do |show|
              expect(show).to have_passed(timeout: 360)
            end
          end
        end
      end
    end
  end
end
