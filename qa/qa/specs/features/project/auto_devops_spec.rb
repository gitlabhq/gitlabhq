module QA
  feature 'Auto Devops', :kubernetes do
    let(:executor) { "qa-runner-#{Time.now.to_i}" }
    let(:config_ru) do
      <<~EOF
        run lambda { |env| [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello World!\n")] }
      EOF
    end
    let(:gemfile) do
      <<~EOF
        source 'https://rubygems.org'
        gem 'rack'
        gem 'rake'
      EOF
    end
    let(:gemfile_lock) do
      <<~EOF
        GEM
          remote: https://rubygems.org/
          specs:
            rack (2.0.4)
            rake (12.3.0)

        PLATFORMS
          ruby

        DEPENDENCIES
          rack
          rake

        BUNDLED WITH
           1.16.1
      EOF
    end
    let(:rakefile) do
      <<~EOF
        require 'rake/testtask'

        task default: %w[test]

        task :test do
          puts "ok"
        end
      EOF
    end

    after do
      @cluster&.remove!
    end

    scenario 'users creates a new project and runs auto devops' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      @cluster = Service::KubernetesCluster.new.create!

      # Create the K8s cluster
      project = Factory::Resource::Project.fabricate! do |p|
        p.name = 'project-with-autodevops'
        p.description = 'Project with Auto Devops'
      end

      # Create Auto Devops compatible repo
      project.visit!
      Git::Repository.perform do |repository|
        repository.uri = Page::Project::Show.act do
          choose_repository_clone_http
          repository_location.uri
        end

        repository.use_default_credentials
        repository.clone
        repository.configure_identity('GitLab QA', 'root@gitlab.com')

        repository.checkout_new_branch('master')
        repository.add_file('config.ru', config_ru)
        repository.add_file('Gemfile', gemfile)
        repository.add_file('Gemfile.lock', gemfile_lock)
        repository.add_file('Rakefile', rakefile)
        repository.commit('Create auto devops repo')
        repository.push_changes("master:master")
      end

      # Connect GitLab to the K8s cluster
      Factory::Resource::KubernetesCluster.fabricate! do |c|
        c.project = project
        c.cluster_name = @cluster.cluster_name
        c.api_url = @cluster.api_url
        c.ca_certificate = @cluster.ca_certificate
        c.token = @cluster.token
        c.install_helm_tiller = true
        c.install_ingress = true
        c.install_prometheus = true
        c.install_runner = true
      end

      require 'pry'; binding.pry

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
