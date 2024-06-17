# frozen_string_literal: true

module Ci
  module Partitionable
    module Switch
      extend ActiveSupport::Concern

      # These methods are cached at the class level and depend on the value
      # of `table_name`, changing that value resets them.
      # `cached_find_by_statement` is used to cache SQL statements which can
      # include the table name.
      #
      SWAPABLE_METHODS = %i[table_name quoted_table_name arel_table
        predicate_builder cached_find_by_statement].freeze

      included do |base|
        partitioned = Class.new(base) do
          self.table_name = base.routing_table_name

          def self.routing_class?
            true
          end
        end

        base.const_set(:Partitioned, partitioned)
      end

      class_methods do
        def routing_class?
          false
        end

        def routing_table_enabled?
          return false if routing_class?

          Gitlab::SafeRequestStore.fetch(routing_table_name_flag) do
            ::Feature.enabled?(routing_table_name_flag, :request, type: :gitlab_com_derisk)
          end
        end

        # We're delegating them to the `Partitioned` model.
        # They do not require any check override since they come from AR core
        # (are always defined) and we're using `super` to get the value.
        #
        SWAPABLE_METHODS.each do |name|
          define_method(name) do |*args, &block|
            if routing_table_enabled?
              self::Partitioned.public_send(name, *args, &block) # rubocop: disable GitlabSecurity/PublicSend
            else
              super(*args, &block)
            end
          end
        end
      end
    end
  end
end
