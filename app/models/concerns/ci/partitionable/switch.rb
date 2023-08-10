# frozen_string_literal: true

module Ci
  module Partitionable
    MUTEX = Mutex.new

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
        install_partitioned_class(base)
      end

      class_methods do
        # `Class.new(partitionable_model)` triggers `partitionable_model.inherited`
        # and we need the mutex to break the recursion without adding extra accessors
        # on the model. This will be used during code loading, not runtime.
        #
        def install_partitioned_class(partitionable_model)
          Partitionable::MUTEX.synchronize do
            partitioned = Class.new(partitionable_model) do
              self.table_name = partitionable_model.routing_table_name

              def self.routing_class?
                true
              end

              def self.sti_name
                superclass.sti_name
              end
            end

            partitionable_model.const_set(:Partitioned, partitioned)
          end
        end

        def inherited(child_class)
          super
          return if Partitionable::MUTEX.owned?

          install_partitioned_class(child_class)
        end

        def routing_class?
          false
        end

        def routing_table_enabled?
          return false if routing_class?

          Gitlab::SafeRequestStore.fetch(routing_table_name_flag) do
            ::Feature.enabled?(routing_table_name_flag)
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

        def type_condition(table = arel_table)
          sti_column = table[inheritance_column]
          sti_names  = ([self] + descendants).map(&:sti_name).uniq

          predicate_builder.build(sti_column, sti_names)
        end
      end
    end
  end
end
