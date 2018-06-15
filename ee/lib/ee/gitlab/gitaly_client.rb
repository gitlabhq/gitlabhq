module EE
  module Gitlab
    module GitalyClient
      extend ::Gitlab::Utils::Override
      extend ActiveSupport::Concern

      module ClassMethods
        # TODO add override once 'explicit_opt_in_required' exists in GitalyClient
        def explicit_opt_in_required
          [::Gitlab::GitalyClient::StorageSettings::DISK_ACCESS_DENIED_FLAG]
        end
      end
    end
  end
end
