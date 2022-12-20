# frozen_string_literal: true

require 'rspec/core'

module QA
  module Specs
    module Helpers
      module FeatureFlag
        extend self

        def skip_or_run_feature_flag_tests_or_contexts(example)
          if example.metadata.key?(:feature_flag)
            feature_flag_tag = example.metadata[:feature_flag]

            global_feature_flag_message = 'Skipping on .com environments due to global feature flag usage'
            feature_flag_message = 'Skipping on production due to feature flag usage'

            if feature_flag_tag.is_a?(Hash) && feature_flag_tag[:scope] == :global
              # Tests using a global feature flag will be skipped on live .com environments.
              # This is to avoid flakiness with other tests running in parallel on the same environment
              # as well as interfering with feature flag experimentation done by development groups.
              example.metadata[:skip] = global_feature_flag_message if ContextSelector.dot_com?
            elsif skip_env_for_scoped_feature_flag
              # Tests using a feature flag scoped to an actor (ex: :project, :user, :group), or
              # with no scope defined (such as in the case of a low risk global feature flag),
              # will only be skipped on environments without an admin account
              example.metadata[:skip] = feature_flag_message
            end
          end
        end

        private

        def skip_env_for_scoped_feature_flag
          ContextSelector.context_matches?(:production) || ContextSelector.context_matches?({ subdomain: :pre })
        end
      end
    end
  end
end
