# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class LazyRelationLoader
        class Registry
          PrematureQueryExecutionTriggered = Class.new(RuntimeError)
          # Following methods are Active Record kicker methods which fire SQL query.
          # We can support some of them with TopNLoader but for now restricting their use
          # as we don't have a use case.
          PROHIBITED_METHODS = (
            ActiveRecord::FinderMethods.instance_methods(false) +
            ActiveRecord::Calculations.instance_methods(false)
          ).to_set.freeze

          def initialize(relation)
            @parents = []
            @relation = relation
            @records = []
            @loaded = false
          end

          def register(object)
            @parents << object
          end

          def method_missing(method_name, ...)
            raise PrematureQueryExecutionTriggered if PROHIBITED_METHODS.include?(method_name)

            result = relation.public_send(method_name, ...) # rubocop:disable GitlabSecurity/PublicSend

            if result.is_a?(ActiveRecord::Relation) # Spawn methods generate a new relation (e.g. where, limit)
              @relation = result

              return self
            end

            result
          end

          def respond_to_missing?(method_name, include_private = false)
            relation.respond_to?(method_name, include_private)
          end

          def load
            return records if loaded

            @loaded = true
            @records = TopNLoader.load(relation, parents)
          end

          def for(object)
            load.select { |record| record[foreign_key] == object[active_record_primary_key] }
                .tap { |records| set_inverse_of(object, records) }
          end

          private

          attr_reader :parents, :relation, :records, :loaded

          delegate :proxy_association, to: :relation, private: true
          delegate :reflection, to: :proxy_association, private: true
          delegate :active_record_primary_key, :foreign_key, to: :reflection, private: true

          def set_inverse_of(object, records)
            records.each do |record|
              object.association(reflection.name).set_inverse_instance(record)
            end
          end
        end
      end
    end
  end
end
