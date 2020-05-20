# frozen_string_literal: true

module QA
  context 'Release', :docker, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/217250', type: :investigating } do
    describe 'Parent-child pipelines dependent relationship' do
      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'pipelines-dependent-relationship'
        end
      end
      let!(:runner) do
        Resource::Runner.fabricate_via_api! do |runner|
          runner.project = project
          runner.name = project.name
          runner.tags = ["#{project.name}"]
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
      end

      it 'parent pipelines passes if child passes' do
        add_ci_files(success_child_ci_file)
        view_pipelines

        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          parent_pipeline.click_linked_job(project.name)

          expect(parent_pipeline).to have_job("child_job")
          expect(parent_pipeline).to have_passed
        end
      end

      it 'parent pipeline fails if child fails' do
        add_ci_files(fail_child_ci_file)
        view_pipelines

        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          parent_pipeline.click_linked_job(project.name)

          expect(parent_pipeline).to have_job("child_job")
          expect(parent_pipeline).to have_failed
        end
      end

      private

      def view_pipelines
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:wait_for_latest_pipeline_completion)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)
      end

      def success_child_ci_file
        {
          file_path: '.child-ci.yml',
          content: <<~YAML
            child_job:
              stage: test
              tags: ["#{project.name}"]
              script: echo "Child job done!"

          YAML
        }
      end

      def fail_child_ci_file
        {
          file_path: '.child-ci.yml',
          content: <<~YAML
            child_job:
              stage: test
              tags: ["#{project.name}"]
              script: exit 1

          YAML
        }
      end

      def parent_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            stages:
              - test
              - deploy

            job1:
              stage: test
              trigger:
                include: ".child-ci.yml"
                strategy: depend

            job2:
              stage: deploy
              tags: ["#{project.name}"]
              script: echo "parent deploy done"

          YAML
        }
      end

      def add_ci_files(child_ci_file)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add parent and child pipelines CI files.'
          commit.add_files(
            [
              child_ci_file,
              parent_ci_file
            ]
          )
        end.project.visit!
      end
    end
  end
end
