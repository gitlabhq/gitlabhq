# frozen_string_literal: true

module API
  # Pages Internal API
  module Internal
    class Pages < Grape::API
      before do
        not_found! unless Feature.enabled?(:pages_internal_api)
        authenticate_gitlab_pages_request!
      end

      helpers do
        def authenticate_gitlab_pages_request!
          unauthorized! unless Gitlab::Pages.verify_api_request(headers)
        end
      end

      namespace 'internal' do
        namespace 'pages' do
          desc 'Get GitLab Pages domain configuration by hostname' do
            detail 'This feature was introduced in GitLab 12.3.'
          end
          params do
            requires :host, type: String, desc: 'The host to query for'
          end
          get "/" do
            host = Namespace.find_by_pages_host(params[:host]) || PagesDomain.find_by_domain(params[:host])
            no_content! unless host

            virtual_domain = host.pages_virtual_domain
            no_content! unless virtual_domain

            present virtual_domain, with: Entities::Internal::Pages::VirtualDomain
          end
        end
      end
    end
  end
end
