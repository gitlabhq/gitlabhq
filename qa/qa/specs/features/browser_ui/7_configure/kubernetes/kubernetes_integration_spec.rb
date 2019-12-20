# frozen_string_literal: true

module QA
  context 'Configure' do
    # This test requires GITLAB_QA_ADMIN_ACCESS_TOKEN to be specified
    describe 'Kubernetes Cluster Integration', :orchestrated, :kubernetes, :requires_admin, :skip do
      context 'Project Clusters' do
        let(:cluster) { Service::KubernetesCluster.new(provider_class: Service::ClusterProvider::K3d).create! }
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'project-with-k8s'
            project.description = 'Project with Kubernetes cluster integration'
          end
        end

        before do
          Flow::Login.sign_in
        end

        after do
          cluster.remove!
        end

        it 'can create and associate a project cluster', :smoke do
          Resource::KubernetesCluster.fabricate_via_browser_ui! do |k8s_cluster|
            k8s_cluster.project = project
            k8s_cluster.cluster = cluster
          end

          project.visit!

          Page::Project::Menu.perform(&:go_to_operations_kubernetes)

          Page::Project::Operations::Kubernetes::Index.perform do |index|
            expect(index).to have_cluster(cluster)
          end
        end

        it 'installs helm and tiller on a gitlab managed app' do
          Resource::KubernetesCluster.fabricate_via_browser_ui! do |k8s_cluster|
            k8s_cluster.project = project
            k8s_cluster.cluster = cluster
            k8s_cluster.install_helm_tiller = true
          end

          Page::Project::Operations::Kubernetes::Show.perform do |show|
            expect(show).to have_application_installed(:helm)
          end
        end
      end
    end
  end
end
