# frozen_string_literal: true

module API
  # Pages Internal API
  module Internal
    class Pages < ::API::Base
      feature_category :pages
      urgency :low

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
            virtual_domain = ::Gitlab::Pages::VirtualHostFinder.new(params[:host]).execute
            no_content! unless virtual_domain

            present virtual_domain, with: Entities::Internal::Pages::VirtualDomain
          end
        end
      end
    end
  end
end
