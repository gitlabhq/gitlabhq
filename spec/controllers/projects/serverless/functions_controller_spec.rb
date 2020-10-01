# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Serverless::FunctionsController do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:cluster) { create(:cluster, :project, :provided_by_gcp, projects: [project]) }
  let(:service) { cluster.platform_kubernetes }
  let(:environment) { create(:environment, project: project) }
  let!(:deployment) { create(:deployment, :success, environment: environment, cluster: cluster) }
  let(:knative_services_finder) { environment.knative_services_finder }
  let(:function_description) { 'A serverless function' }
  let(:function_name) { 'some-function-name' }
  let(:knative_stub_options) do
    { namespace: namespace.namespace, name: function_name, description: function_description }
  end

  let(:knative) { create(:clusters_applications_knative, :installed, cluster: cluster) }

  let(:namespace) do
    create(:cluster_kubernetes_namespace,
      cluster: cluster,
      cluster_project: cluster.cluster_project,
      project: cluster.cluster_project.project,
      environment: environment)
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
    let(:expected_json) { { 'knative_installed' => knative_state, 'functions' => functions } }

    context 'when cache is being read' do
      let(:knative_state) { 'checking' }
      let(:functions) { [] }

      before do
        get :index, params: params({ format: :json })
      end

      it 'returns checking' do
        expect(json_response).to eq expected_json
      end

      it { expect(response).to have_gitlab_http_status(:ok) }
    end

    context 'when cache is ready' do
      let(:knative_state) { true }

      before do
        allow(Clusters::KnativeServicesFinder)
          .to receive(:new)
          .and_return(knative_services_finder)
        synchronous_reactive_cache(knative_services_finder)
        stub_kubeclient_service_pods(
          kube_response({ "kind" => "PodList", "items" => [] }),
          namespace: namespace.namespace
        )
      end

      context 'when no functions were found' do
        let(:functions) { [] }

        before do
          stub_kubeclient_knative_services(
            namespace: namespace.namespace,
            response: kube_response({ "kind" => "ServiceList", "items" => [] })
          )
          get :index, params: params({ format: :json })
        end

        it 'returns checking' do
          expect(json_response).to eq expected_json
        end

        it { expect(response).to have_gitlab_http_status(:ok) }
      end

      context 'when functions were found' do
        let(:functions) { [{}, {}] }

        before do
          stub_kubeclient_knative_services(namespace: namespace.namespace, cluster_id: cluster.id, name: function_name)
        end

        it 'returns functions' do
          get :index, params: params({ format: :json })
          expect(json_response["functions"]).not_to be_empty
        end

        it 'filters out the functions whose cluster the user does not have permission to read' do
          allow(controller).to receive(:can?).and_return(true)
          expect(controller).to receive(:can?).with(user, :read_cluster, cluster).and_return(false)

          get :index, params: params({ format: :json })

          expect(json_response["functions"]).to be_empty
        end

        it 'returns a successful response status' do
          get :index, params: params({ format: :json })
          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'when there is serverless domain for a cluster' do
          let!(:serverless_domain_cluster) do
            create(:serverless_domain_cluster, clusters_applications_knative_id: knative.id)
          end

          it 'returns JSON with function details with serverless domain URL' do
            get :index, params: params({ format: :json })
            expect(response).to have_gitlab_http_status(:ok)

            expect(json_response["functions"]).not_to be_empty

            expect(json_response["functions"]).to all(
              include(
                'url' => "https://#{function_name}-#{serverless_domain_cluster.uuid[0..1]}a1#{serverless_domain_cluster.uuid[2..-3]}f2#{serverless_domain_cluster.uuid[-2..-1]}#{"%x" % environment.id}-#{environment.slug}.#{serverless_domain_cluster.domain}"
              )
            )
          end
        end

        context 'when there is no serverless domain for a cluster' do
          it 'keeps function URL as it was' do
            expect(::Serverless::Domain).not_to receive(:new)

            get :index, params: params({ format: :json })
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end

  describe 'GET #show' do
    context 'with function that does not exist' do
      it 'returns 404' do
        get :show, params: params({ format: :json, environment_id: "*", id: "foo" })
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with valid data', :use_clean_rails_memory_store_caching do
      shared_examples 'GET #show with valid data' do
        context 'when there is serverless domain for a cluster' do
          let!(:serverless_domain_cluster) do
            create(:serverless_domain_cluster, clusters_applications_knative_id: knative.id)
          end

          it 'returns JSON with function details with serverless domain URL' do
            get :show, params: params({ format: :json, environment_id: "*", id: function_name })
            expect(response).to have_gitlab_http_status(:ok)

            expect(json_response).to include(
              'url' => "https://#{function_name}-#{serverless_domain_cluster.uuid[0..1]}a1#{serverless_domain_cluster.uuid[2..-3]}f2#{serverless_domain_cluster.uuid[-2..-1]}#{"%x" % environment.id}-#{environment.slug}.#{serverless_domain_cluster.domain}"
            )
          end

          it 'returns 404 when user does not have permission to read the cluster' do
            allow(controller).to receive(:can?).and_return(true)
            expect(controller).to receive(:can?).with(user, :read_cluster, cluster).and_return(false)

            get :show, params: params({ format: :json, environment_id: "*", id: function_name })

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when there is no serverless domain for a cluster' do
          it 'keeps function URL as it was' do
            get :show, params: params({ format: :json, environment_id: "*", id: function_name })
            expect(response).to have_gitlab_http_status(:ok)

            expect(json_response).to include(
              'url' => "http://#{function_name}.#{namespace.namespace}.example.com"
            )
          end
        end

        it 'return json with function details' do
          get :show, params: params({ format: :json, environment_id: "*", id: function_name })
          expect(response).to have_gitlab_http_status(:ok)

          expect(json_response).to include(
            'name' => function_name,
            'url' => "http://#{function_name}.#{namespace.namespace}.example.com",
            'description' => function_description,
            'podcount' => 0
          )
        end
      end

      context 'on Knative 0.5.0' do
        before do
          prepare_knative_stubs(knative_05_service(**knative_stub_options))
        end

        include_examples 'GET #show with valid data'
      end

      context 'on Knative 0.6.0' do
        before do
          prepare_knative_stubs(knative_06_service(**knative_stub_options))
        end

        include_examples 'GET #show with valid data'
      end

      context 'on Knative 0.7.0' do
        before do
          prepare_knative_stubs(knative_07_service(**knative_stub_options))
        end

        include_examples 'GET #show with valid data'
      end

      context 'on Knative 0.9.0' do
        before do
          prepare_knative_stubs(knative_09_service(**knative_stub_options))
        end

        include_examples 'GET #show with valid data'
      end
    end
  end

  describe 'GET #metrics' do
    context 'invalid data' do
      it 'has a bad function name' do
        get :metrics, params: params({ format: :json, environment_id: "*", id: "foo" })
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end

  describe 'GET #index with data', :use_clean_rails_memory_store_caching do
    shared_examples 'GET #index with data' do
      it 'has data' do
        get :index, params: params({ format: :json })

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response).to match({
                                         'knative_installed' => 'checking',
                                         'functions' => [
                                           a_hash_including(
                                             'name' => function_name,
                                             'url' => "http://#{function_name}.#{namespace.namespace}.example.com",
                                             'description' => function_description
                                           )
                                         ]
                                       })
      end

      it 'has data in html' do
        get :index, params: params

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'on Knative 0.5.0' do
      before do
        prepare_knative_stubs(knative_05_service(**knative_stub_options))
      end

      include_examples 'GET #index with data'
    end

    context 'on Knative 0.6.0' do
      before do
        prepare_knative_stubs(knative_06_service(**knative_stub_options))
      end

      include_examples 'GET #index with data'
    end

    context 'on Knative 0.7.0' do
      before do
        prepare_knative_stubs(knative_07_service(**knative_stub_options))
      end

      include_examples 'GET #index with data'
    end

    context 'on Knative 0.9.0' do
      before do
        prepare_knative_stubs(knative_09_service(**knative_stub_options))
      end

      include_examples 'GET #index with data'
    end
  end

  def prepare_knative_stubs(knative_service)
    stub_kubeclient_service_pods
    stub_reactive_cache(knative_services_finder,
                        {
                          services: [knative_service],
                          pods: kube_knative_pods_body(cluster.project.name, namespace.namespace)["items"]
                        },
                        *knative_services_finder.cache_args)
  end
end
