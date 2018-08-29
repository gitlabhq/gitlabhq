require 'pathname'

module QA
  describe 'Auto Devops', :orchestrated, :kubernetes do
    after do
      @cluster&.remove!
    end

    it 'user creates a new project and runs auto devops' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      project = Factory::Resource::Project.fabricate! do |p|
        p.name = 'project-with-autodevops'
        p.description = 'Project with Auto Devops'
      end

      # Disable code_quality check in Auto DevOps pipeline as it takes
      # too long and times out the test
      Factory::Resource::SecretVariable.fabricate! do |resource|
        resource.key = 'CODE_QUALITY_DISABLED'
        resource.value = '1'
      end

      # Create Auto Devops compatible repo
      Factory::Repository::ProjectPush.fabricate! do |push|
        push.project = project
        push.directory = Pathname
          .new(__dir__)
          .join('../../../fixtures/auto_devops_rack')
        push.commit_message = 'Create Auto DevOps compatible rack application'
      end

      Page::Project::Show.act { wait_for_push }

      # Create and connect K8s cluster
      @cluster = Service::KubernetesCluster.new.create!
      kubernetes_cluster = Factory::Resource::KubernetesCluster.fabricate! do |cluster|
        cluster.project = project
        cluster.cluster = @cluster
        cluster.install_helm_tiller = true
        cluster.install_ingress = true
        cluster.install_prometheus = true
        cluster.install_runner = true
      end

      project.visit!
      Page::Menu::Side.act { click_ci_cd_settings }
      Page::Project::Settings::CICD.perform do |p|
        p.enable_auto_devops_with_domain("#{kubernetes_cluster.ingress_ip}.nip.io")
      end

      project.visit!
      Page::Menu::Side.act { click_ci_cd_pipelines }
      Page::Project::Pipeline::Index.act { go_to_latest_pipeline }

      Page::Project::Pipeline::Show.perform do |pipeline|
        expect(pipeline).to have_build('build', status: :success, wait: 600)
        expect(pipeline).to have_build('test', status: :success, wait: 600)
        expect(pipeline).to have_build('production', status: :success, wait: 1200)
      end
    end
  end
end
