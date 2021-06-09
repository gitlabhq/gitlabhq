# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environment > Pod Logs', :js, :kubeclient do
  include KubernetesHelpers

  let(:pod_names) { %w(kube-pod) }
  let(:pod_name) { pod_names.first }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, project: project) }
  let(:service) { create(:cluster_platform_kubernetes, :configured) }

  before do
    cluster = create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [project])
    create(:deployment, :success, environment: environment)

    stub_kubeclient_pods(environment.deployment_namespace)
    stub_kubeclient_logs(pod_name, environment.deployment_namespace, container: 'container-0')
    stub_kubeclient_deployments(environment.deployment_namespace)
    stub_kubeclient_ingresses(environment.deployment_namespace)
    stub_kubeclient_nodes_and_nodes_metrics(cluster.platform.api_url)

    sign_in(project.owner)
  end

  it "shows environments in dropdown" do
    create(:environment, project: project)

    visit project_logs_path(environment.project, environment_name: environment.name, pod_name: pod_name)

    wait_for_requests

    page.within('.js-environments-dropdown') do
      toggle = find(".dropdown-toggle:not([disabled])")

      expect(toggle).to have_content(environment.name)

      toggle.click

      dropdown_items = find(".dropdown-menu").all(".dropdown-item")
      expect(dropdown_items.first).to have_content(environment.name)
      expect(dropdown_items.size).to eq(2)
    end
  end

  context 'with logs', :use_clean_rails_memory_store_caching do
    it "shows pod logs", :sidekiq_might_not_need_inline do
      visit project_logs_path(environment.project, environment_name: environment.name, pod_name: pod_name)

      wait_for_requests

      page.within('.qa-pods-dropdown') do
        find(".dropdown-toggle:not([disabled])").click

        dropdown_items = find(".dropdown-menu").all(".dropdown-item:not([disabled])")
        expect(dropdown_items.size).to eq(1)

        dropdown_items.each_with_index do |item, i|
          expect(item.text).to eq(pod_names[i])
        end
      end
      expect(page).to have_content("kube-pod | Log 1")
      expect(page).to have_content("kube-pod | Log 2")
      expect(page).to have_content("kube-pod | Log 3")
    end
  end
end
