# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, :external_api_calls,
    feature_flag: { name: 'rubygem_packages', scope: :project } do
    describe 'RubyGems Repository', product_group: :package_registry do
      include Runtime::Fixtures

      let(:project) { create(:project, :private, name: 'rubygems-package-project') }
      let(:package) { build(:package, name: "mygem-#{SecureRandom.hex(8)}", project: project) }

      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{Time.now.to_i}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      let(:gitlab_address_with_port) do
        Support::GitlabAddress.address_with_port
      end

      before do
        Runtime::Feature.enable(:rubygem_packages, project: project)
      end

      after do
        Runtime::Feature.disable(:rubygem_packages, project: project)
      end

      it 'publishes a Ruby gem', :blocking, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347649',
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/366099',
          type: :flaky
        } do
        Flow::Login.sign_in

        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          rubygem_upload_yaml = ERB.new(read_fixture('package_managers/rubygems', 'rubygems_upload_package.yaml.erb')).result(binding)
          rubygem_package_gemspec = ERB.new(read_fixture('package_managers/rubygems', 'package.gemspec.erb')).result(binding)

          create(:commit, project: project, commit_message: 'Add package files', actions: [
            {
              action: 'create',
              file_path: '.gitlab-ci.yml',
              content: rubygem_upload_yaml
            },
            {
              action: 'create',
              file_path: 'lib/hello_gem.rb',
              content: <<~RUBY
                class HelloWorld
                  def self.hi
                    puts "Hello world!"
                  end
                end
              RUBY
            },
            {
              action: 'create',
              file_path: "#{package.name}.gemspec",
              content: rubygem_package_gemspec
            }
          ])
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('test_package')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 180)
        end

        Page::Project::Menu.perform(&:go_to_package_registry)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)
        end
      end
    end
  end
end
