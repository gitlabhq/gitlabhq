module QA
  feature 'Auto Devops', :kubernetes, :docker do
    let(:executor) { "qa-runner-#{Time.now.to_i}" }

    after do
      @cluster&.remove!
    end

    scenario 'users creates a new project and runs auto devops' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      #@cluster = Service::KubernetesCluster.new.create!

      project = Factory::Resource::Project.fabricate! do |project|
        project.name = 'project-with-autodevops'
        project.description = 'Project with Auto Devops'
      end

      #Factory::Repository::Push.fabricate! do |push|
      #  push.project = project
      #  push.file_name = 'config.ru'
      #  push.commit_message = 'Add config.ru'
      #  push.file_content = <<~EOF run lambda { |env| [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello World!\n")] }
      #  EOF
      #end

      #Factory::Repository::Push.fabricate! do |push|
      #  push.project = project
      #  push.file_name = 'Gemfile'
      #  push.commit_message = 'Add Gemfile'
      #  push.file_content = <<~EOF
      #    source 'https://rubygems.org'
      #    gem 'rack'
      #    gem 'rake'
      #  EOF
      #end

      #Factory::Repository::Push.fabricate! do |push|
      #  push.project = project
      #  push.file_name = 'Gemfile.lock'
      #  push.commit_message = 'Add Gemfile.lock'
      #  push.file_content = <<~EOF
      #    GEM
      #      remote: https://rubygems.org/
      #      specs:
      #        rack (2.0.4)
      #        rake (12.3.0)

      #    PLATFORMS
      #      ruby

      #    DEPENDENCIES
      #      rack
      #      rake

      #    BUNDLED WITH
      #       1.16.1
      #  EOF
      #end

      #Factory::Repository::Push.fabricate! do |push|
      #  push.project = project
      #  push.file_name = 'Rakefile'
      #  push.commit_message = 'Add Rakefile'
      #  push.file_content = <<~EOF
      #    require 'rake/testtask'

      #    task default: %w[test]

      #    task :test do
      #      puts "ok"
      #    end
      #  EOF
      #end

      Factory::Resource::KubernetesCluster.fabricate! do |c|
        c.project = project
        c.cluster_name = "blah1"#@cluster.cluster_name
        c.api_url = "blah2"#@cluster.api_url
        c.ca_certificate = "blah3"#@cluster.ca_certificate
        c.token = "blah4"#@cluster.token
        c.install_helm_tiller = true
        c.install_ingress = true
        c.install_prometheus = true
        c.install_runner = true
      end

      #Page::Project::Settings::CICD.act { enable_auto_devops_with_nip_domain }

      #puts 'Waiting for the runner to process the pipeline'
      #sleep 15 # Runner should process all jobs within 15 seconds.

      #Page::Project::Pipeline::Index.act { go_to_latest_pipeline }

      #Page::Project::Pipeline::Show.perform do |pipeline|
      #  expect(pipeline).to have_build('build', status: :success)
      #  expect(pipeline).to have_build('test', status: :success)
      #  expect(pipeline).to have_build('production', status: :success)
      #end
    end
  end
end
