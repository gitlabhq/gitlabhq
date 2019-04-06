# frozen_string_literal: true

require 'spec_helper'

describe Projects::Serverless::FunctionsController do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  let(:user) { create(:user) }
  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:knative) { create(:clusters_applications_knative, :installed, cluster: cluster) }
  let(:service) { cluster.platform_kubernetes }
  let(:project) { cluster.project}

  let(:namespace) do
    create(:cluster_kubernetes_namespace,
      cluster: cluster,
      cluster_project: cluster.cluster_project,
      project: cluster.cluster_project.project)
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  def params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace.to_param,
                       project_id: project.to_param)
  end

  describe 'GET #index' do
    context 'empty cache' do
      it 'has no data' do
        get :index, params: params({ format: :json })

        expect(response).to have_gitlab_http_status(204)
      end

      it 'renders an html page' do
        get :index, params: params

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  describe 'GET #show' do
    context 'invalid data' do
      it 'has a bad function name' do
        get :show, params: params({ format: :json, environment_id: "*", id: "foo" })
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'valid data', :use_clean_rails_memory_store_caching do
      before do
        stub_kubeclient_service_pods
        stub_reactive_cache(knative,
          {
            services: kube_knative_services_body(namespace: namespace.namespace, name: cluster.project.name)["items"],
            pods: kube_knative_pods_body(cluster.project.name, namespace.namespace)["items"]
          })
      end

      it 'has a valid function name' do
        get :show, params: params({ format: :json, environment_id: "*", id: cluster.project.name })
        expect(response).to have_gitlab_http_status(200)

        expect(json_response).to include(
          "name" => project.name,
          "url" => "http://#{project.name}.#{namespace.namespace}.example.com",
          "podcount" => 1
        )
      end
    end
  end

  describe 'GET #metrics' do
    context 'invalid data' do
      it 'has a bad function name' do
        get :metrics, params: params({ format: :json, environment_id: "*", id: "foo" })
        expect(response).to have_gitlab_http_status(204)
      end
    end
  end

  describe 'GET #index with data', :use_clean_rails_memory_store_caching do
    before do
      stub_kubeclient_service_pods
      stub_reactive_cache(knative,
        {
          services: kube_knative_services_body(namespace: namespace.namespace, name: cluster.project.name)["items"],
          pods: kube_knative_pods_body(cluster.project.name, namespace.namespace)["items"]
        })
    end

    it 'has data' do
      get :index, params: params({ format: :json })

      expect(response).to have_gitlab_http_status(200)

      expect(json_response).to contain_exactly(
        a_hash_including(
          "name" => project.name,
          "url" => "http://#{project.name}.#{namespace.namespace}.example.com"
        )
      )
    end

    it 'has data in html' do
      get :index, params: params

      expect(response).to have_gitlab_http_status(200)
    end
  end
end
