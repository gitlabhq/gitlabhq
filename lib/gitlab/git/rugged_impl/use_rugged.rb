# frozen_string_literal: true

module Gitlab
  module Git
    module RuggedImpl
      module UseRugged
        def use_rugged?(repo, feature_key)
          feature = Feature.get(feature_key)
          return feature.enabled? if Feature.persisted?(feature)

          Gitlab::GitalyClient.can_use_disk?(repo.storage)
        end

        def execute_rugged_call(method_name, *args)
          Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            start = Gitlab::Metrics::System.monotonic_time

            result = send(method_name, *args) # rubocop:disable GitlabSecurity/PublicSend

            duration = Gitlab::Metrics::System.monotonic_time - start

            if Gitlab::RuggedInstrumentation.active?
              Gitlab::RuggedInstrumentation.increment_query_count
              Gitlab::RuggedInstrumentation.query_time += duration

              Gitlab::RuggedInstrumentation.add_call_details(
                feature: method_name,
                args: args,
                duration: duration,
                backtrace: Gitlab::BacktraceCleaner.clean_backtrace(caller))
            end

            result
          end
        end
      end
    end
  end
end
