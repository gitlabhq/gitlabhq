# frozen_string_literal: true

module QA
  RSpec.shared_context 'npm docker container publish and install' do
    let(:package_json_file) do
      {
        file_path: 'package.json',
        content: <<~JSON
          {
            "name": "#{package.name}",
            "version": "1.0.0",
            "description": "Example package for GitLab npm registry",
            "publishConfig": {
              "@#{registry_scope}:registry": "#{gitlab_address_without_port}/api/v4/projects/#{project.id}/packages/npm/"
            }
          }
        JSON
      }
    end

    before do
      with_fixtures([package_json_file]) do |dir|
        Service::DockerRun::Npm.new(
          dir,
          gitlab_address_without_port: gitlab_address_without_port,
          package_name: package.name,
          registry_scope: registry_scope,
          package_project_id: project.id,
          install_registry_url: install_registry_url,
          token: token
        ).publish_and_install!
      end
    end

    shared_examples 'using a docker container' do |testcase|
      it 'push and pull a npm package', testcase: testcase do
        project.visit!

        Page::Project::Menu.perform(&:go_to_package_registry)
        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)

          index.click_package(package.name)
        end

        Page::Project::Packages::Show.perform do |show|
          expect(show).to have_package_info(name: package.name, version: "1.0.0")
        end
      end
    end
  end
end
