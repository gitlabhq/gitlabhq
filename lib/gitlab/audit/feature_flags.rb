# frozen_string_literal: true

module Gitlab
  module Audit
    module FeatureFlags
      # Overridden in EE::Gitlab::Audit::FeatureFlags
      def self.stream_from_new_tables?(_entity); end
    end
  end
end

Gitlab::Audit::FeatureFlags.singleton_class.prepend_mod_with('Gitlab::Audit::FeatureFlags')
