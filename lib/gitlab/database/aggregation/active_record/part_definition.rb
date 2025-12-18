# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class PartDefinition < ::Gitlab::Database::Aggregation::PartDefinition
          attr_reader :scope_proc

          def initialize(*args, scope_proc: nil, **kwargs)
            super
            @scope_proc = scope_proc
          end

          def apply_scope(scope, context)
            scope_proc ? scope_proc.call(scope, context) : scope
          end
        end
      end
    end
  end
end
