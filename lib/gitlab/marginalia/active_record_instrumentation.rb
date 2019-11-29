# frozen_string_literal: true

# Patch to annotate sql only when the feature is enabled.
module Gitlab
  module Marginalia
    module ActiveRecordInstrumentation
      # CAUTION:
      # Any method call which generates a query inside this function will get into a recursive loop unless called within `Marginalia.without_annotation` method.
      def annotate_sql(sql)
        if ActiveRecord::Base.connected? &&
          ::Marginalia.annotation_allowed? &&
          ::Marginalia.without_annotation { Gitlab::Marginalia.feature_enabled? }
          super(sql)
        else
          sql
        end
      end
    end
  end
end
