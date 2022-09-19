# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Create a new project from a template', product_group: :source_code do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'templated-project'
          project.template_name = 'dotnetcore'
        end
      end

      it 'commits via the api', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/357234' do
        expect do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.update_files(
              [
                {
                    file_path: '.gitlab-ci.yml',
                    content: 'script'
                }
              ]
            )
            commit.add_files(
              [
                {
                    file_path: 'foo',
                    content: 'bar'
                }
              ]
            )
          end
        end.not_to raise_exception
      end
    end
  end
end
