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

          route_setting :authorization, skip_granular_token_authorization: :internal_testing
          get do
            # Fetch runtime coverage data which is tracked during E2E spec execution
            # Returns full line-level coverage data: { "file.rb" => { "1" => "5", "2" => "3" } }
            # skip hash check due to hash mismatch on some environments which results in empty coverage data
            ::Coverband.configuration.store.coverage(::Coverband::RUNTIME_TYPE, skip_hash_check: true)
          end

          route_setting :authorization, skip_granular_token_authorization: :internal_testing
          delete do
            ::Coverband.configuration.store.clear!

            status 200
            {
              message: "Cleared source code paths coverage mapping"
            }
          end
        end
      end
    end
  end
end
