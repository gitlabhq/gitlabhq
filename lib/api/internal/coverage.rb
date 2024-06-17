# frozen_string_literal: true

#  This api is for internal use only for the purpose of source code paths mapping to E2E specs.

module API
  module Internal
    class Coverage < ::API::Base
      feature_category :code_testing
      urgency :low

      before do
        authenticated_as_admin!
      end

      namespace 'internal' do
        namespace 'coverage' do
          desc 'Source code paths coverage mapping' do
            success code: 200, message: 'Success'
            failure [
              { code: 401, message: 'Unauthorized' }
            ]
          end

          get do
            coverage = ::Coverband.configuration.store.coverage
            coverage&.keys
          end

          delete do
            ::Coverband.configuration.store.clear!
          end
        end
      end
    end
  end
end
