# frozen_string_literal: true

module API
  # Pages Internal API
  module Internal
    class Pages < ::API::Base
      feature_category :pages

      before do
        authenticate_gitlab_pages_request!
      end

      helpers do
        def authenticate_gitlab_pages_request!
          unauthorized! unless Gitlab::Pages.verify_api_request(headers)
        end
      end

      namespace 'internal' do
        namespace 'pages' do
          desc 'Indicates that pages API is enabled and auth token is valid' do
            detail 'This feature was introduced in GitLab 12.10.'
          end
          get "status" do
            no_content!
          end

          desc 'Get GitLab Pages domain configuration by hostname' do
            detail 'This feature was introduced in GitLab 12.3.'
          end
          params do
            requires :host, type: String, desc: 'The host to query for'
          end
          get "/" do
            ##
            # Serverless domain proxy has been deprecated and disabled as per
            #   https://gitlab.com/gitlab-org/gitlab-pages/-/issues/467
            #
            # serverless_domain_finder = ServerlessDomainFinder.new(params[:host])
            # if serverless_domain_finder.serverless?
            #   # Handle Serverless domains
            #   serverless_domain = serverless_domain_finder.execute
            #   no_content! unless serverless_domain
            #
            #   virtual_domain = Serverless::VirtualDomain.new(serverless_domain)
            #   no_content! unless virtual_domain
            #
            #   present virtual_domain, with: Entities::Internal::Serverless::VirtualDomain
            # end

            host = Namespace.find_by_pages_host(params[:host]) || PagesDomain.find_by_domain_case_insensitive(params[:host])
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
