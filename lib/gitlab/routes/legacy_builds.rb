module Gitlab
  module Routes
    class LegacyBuilds
      include Gitlab::Routing.url_helpers
      include GitlabRoutingHelper

      def initialize(map)
        @map = map
      end

      def draw
        @map.instance_eval do
          resources :builds, only: [:index, :show], constraints: { id: /\d+/ } do
            collection do
              resources :artifacts, only: [], controller: 'build_artifacts' do
                collection do
                  get :latest_succeeded,
                    path: '*ref_name_and_path',
                    format: false
                end
              end
            end

            member do
              get :status
              get :trace, defaults: { format: 'json' }
              get :raw
            end

            resource :artifacts, only: [], controller: 'build_artifacts' do
              get :download
              get :browse, path: 'browse(/*path)', format: false
              get :file, path: 'file/*path', format: false
              get :raw, path: 'raw/*path', format: false
            end
          end
        end
      end
    end
  end
end
