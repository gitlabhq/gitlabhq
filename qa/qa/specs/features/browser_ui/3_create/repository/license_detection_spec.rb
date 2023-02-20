# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Repository License Detection', product_group: :source_code do
      after do
        project.remove_via_api!
      end

      let(:project) { Resource::Project.fabricate_via_api! }

      shared_examples 'project license detection' do
        it 'displays the name of the license on the repository' do
          license_path = File.join(Runtime::Path.fixtures_path, 'software_licenses', license_file_name)
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.add_files([{ file_path: 'LICENSE', content: File.read(license_path) }])
          end

          project.visit!

          Page::Project::Show.perform do |show|
            expect(show).to have_license(rendered_license_name)
          end
        end
      end

      context 'on a project with a commonly used LICENSE',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366842' do
        it_behaves_like 'project license detection' do
          let(:license_file_name) { 'bsd-3-clause' }
          let(:rendered_license_name) { 'BSD 3-Clause "New" or "Revised" License' }
        end
      end

      context 'on a project with an unrecognized LICENSE',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366843' do
        it_behaves_like 'project license detection' do
          let(:license_file_name) { 'other' }
          let(:rendered_license_name) { 'LICENSE' }
        end
      end
    end
  end
end
