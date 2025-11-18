# frozen_string_literal: true

module QA
  module Support
    # Common tools for use with test metrics setup
    #
    module TestMetricsTools
      LIVE_ENVS = %w[staging staging-canary staging-ref canary preprod production].freeze

      private

      delegate :ci_project_name, to: "QA::Runtime::Env"

      # Test run type
      # Automatically infer for staging (`gstg`, `gstg-cny`, `gstg-ref`), canary, preprod or production env
      #
      # @return [String, nil]
      def run_type
        @run_type ||= if env('QA_RUN_TYPE')
                        env('QA_RUN_TYPE')
                      elsif LIVE_ENVS.exclude?(ci_project_name)
                        nil
                      else
                        test_subset = if env('SMOKE_ONLY') == 'true'
                                        'sanity'
                                      else
                                        'full'
                                      end

                        "#{ci_project_name}-#{test_subset}"
                      end
      end

      # Merge request iid
      #
      # @return [String]
      def merge_request_iid
        env('CI_MERGE_REQUEST_IID') || env('TOP_UPSTREAM_MERGE_REQUEST_IID')
      end

      # Return non empty environment variable value
      #
      # @param [String] name
      # @return [String, nil]
      def env(name)
        return unless ENV[name] && !ENV[name].empty?

        ENV[name]
      end
    end
  end
end
