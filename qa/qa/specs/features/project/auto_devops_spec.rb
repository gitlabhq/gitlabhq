module QA
  feature 'Auto Devops', :kubernetes do
    let(:executor) { "qa-runner-#{Time.now.to_i}" }

    after do
      @cluster&.remove!
    end

    scenario 'user creates a new project and runs auto devops' do
      @cluster = Service::KubernetesCluster.new.create!
      require 'pry'; binding.pry
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      project = Factory::Resource::Project.fabricate! do |p|
        p.name = 'project-with-k8s-runner'
        p.description = 'Project with K8s Runner'
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
        repository.add_file('.gitlab-ci.yml', File.read(File.join(__dir__, "../../../fixtures/auto_devops_rack/delete_me-ci.yml")))
        repository.commit('Create auto devops repo')
        repository.push_changes("master:master")
      end

      # Create and connect K8s cluster
      @cluster = Service::KubernetesCluster.new.create!
      kubernetes_cluster = Factory::Resource::KubernetesCluster.fabricate! do |c|
        c.project = project
        c.cluster = @cluster
        c.install_helm_tiller = true
        c.install_runner = true
      end

      project.visit!
      Page::Menu::Side.act { click_ci_cd_pipelines }
      Page::Project::Pipeline::Index.act { go_to_latest_pipeline }

      require 'pry'; binding.pry
    end
  end
end
