# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage,
                            feature_flag: { name: 'rubygem_packages', scope: :project } do
    describe 'RubyGems Repository', product_group: :package_registry do
      include Runtime::Fixtures

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'rubygems-package-project'
          project.visibility = :private
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = "mygem-#{SecureRandom.hex(8)}"
          package.project = project
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.name}"]
          runner.executor = :docker
          runner.project = project
        end
      end

      let(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      before do
        Runtime::Feature.enable(:rubygem_packages, project: project)
      end

      after do
        Runtime::Feature.disable(:rubygem_packages, project: project)
      end

      it 'publishes a Ruby gem', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347649' do
        Flow::Login.sign_in

        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            rubygem_upload_yaml = ERB.new(read_fixture('package_managers/rubygems', 'rubygems_upload_package.yaml.erb')).result(binding)
            rubygem_package_gemspec = ERB.new(read_fixture('package_managers/rubygems', 'package.gemspec.erb')).result(binding)

            commit.project = project
            commit.commit_message = 'Add package files'
            commit.add_files(
              [
                {
                  file_path: '.gitlab-ci.yml',
                  content: rubygem_upload_yaml
                },
                {
                  file_path: 'lib/hello_gem.rb',
                  content:
                    <<~RUBY
                      class HelloWorld
                        def self.hi
                          puts "Hello world!"
                        end
                      end
                    RUBY
                },
                {
                  file_path: "#{package.name}.gemspec",
                  content: rubygem_package_gemspec
                }
              ]
            )
          end
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('test_package')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Page::Project::Menu.perform(&:go_to_package_registry)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)
        end
      end
    end
  end
end
