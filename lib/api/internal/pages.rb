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
          get "/" do
            status :ok
          end
        end
      end
    end
  end
end
