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

        def wrap_rugged_call(&block)
          Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            yield
          end
        end
      end
    end
  end
end
