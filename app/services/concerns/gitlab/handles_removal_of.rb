# frozen_string_literal: true

# Declares the dependent tables a destroy service is responsible for cleaning up.
# Foreign keys to destroy-service tables cascade only as a backstop for manual
# admin deletes; the destroy service must explicitly delete dependents (object
# storage, counters, audit events). Declarations here are checked against real
# foreign keys by foreign_keys_to_destroy_service_tables_spec.rb.
#
# Usage:
#   include Gitlab::HandlesRemovalOf
#   handles_removal_of :widgets, :widget_settings
module Gitlab
  module HandlesRemovalOf
    extend ActiveSupport::Concern

    class_methods do
      def handles_removal_of(*tables)
        own_handled_tables.merge(tables.map(&:to_s))
      end

      def handled_tables
        inherited = superclass.respond_to?(:handled_tables) ? superclass.handled_tables : Set.new

        inherited + own_handled_tables
      end

      # Declarations made on this class itself, excluding inherited ones.
      def own_handled_tables
        @own_handled_tables ||= Set.new
      end
    end
  end
end
