# frozen_string_literal: true

# Patch to annotate sql only when the feature is enabled.
module Gitlab
  module Marginalia
    module ActiveRecordInstrumentation
      def annotate_sql(sql)
        Gitlab::Marginalia.cached_feature_enabled? ? super(sql) : sql
      end
    end
  end
end
