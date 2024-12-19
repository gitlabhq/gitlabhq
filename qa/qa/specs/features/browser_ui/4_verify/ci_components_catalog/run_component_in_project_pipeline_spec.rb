# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
    describe 'CI component', :skip_live_env do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:tag) { '1.0.0' }
      let(:test_stage) { 'test' }
      let(:test_phrase) { 'this is NOT secret!!!!!!!' }
      let(:domain_name) { Support::GitlabAddress.host_with_port(with_default_port: false) }

      let(:component_project) do
        create(:project, :with_readme, name: 'component-project', description: 'This is a project with CI component.')
      end

      let(:test_project) do
        create(:project, :with_readme, name: 'project-to-test-component')
      end

      let!(:runner) { create(:project_runner, project: test_project, name: executor, tags: [executor]) }

      let(:component_content) do
        <<~YAML
          spec:
            inputs:
              secret-phrase:
                default: 'this is secret'
              stage:
                default: "#{test_stage}"
          ---
          my-component:
            script: echo $[[ inputs.secret-phrase ]]
        YAML
      end

      let(:ci_yml_content) do
        <<~YAML
          default:
            tags: ["#{executor}"]

          include:
            - component: "#{domain_name}/#{component_project.full_path}/new-component@#{tag}"
              inputs:
                secret-phrase: #{test_phrase}

          cat:
            stage: deploy
            script: echo 'Meow'
        YAML
      end

      before do
        Flow::Login.sign_in
        Flow::Project.enable_catalog_resource_feature(component_project)

        add_ci_file(component_project, 'templates/new-component.yml', component_content)
        component_project.create_release(tag)
        QA::Runtime::Logger.info("Waiting for #{component_project.name}'s release #{tag} to be available")
        Support::Waiter.wait_until { component_project.has_release?(tag) }

        test_project.visit!
        add_ci_file(test_project, '.gitlab-ci.yml', ci_yml_content)
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: test_project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: test_project, status: 'success')
      end

      after do
        runner.remove_via_api!
      end

      it 'runs in project pipeline with correct inputs', :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/451582' do
        test_project.visit_latest_pipeline
        Page::Project::Pipeline::Show.perform do |show|
          expect(show).to have_stage(test_stage), "Expected pipeline to have stage #{test_stage} but not found."
        end

        test_project.visit_job('my-component')
        Page::Project::Job::Show.perform do |show|
          expect(show.output).to have_content(test_phrase), "Component job failed to use custom phrase #{test_phrase}."
        end
      end

      private

      def add_ci_file(project, file_path, content)
        create(:commit, project: project, commit_message: 'Add CI yml file', actions: [
          {
            action: 'create',
            file_path: file_path,
            content: content
          }
        ])
      end
    end
  end
end
