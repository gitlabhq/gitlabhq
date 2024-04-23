# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Base
      # Base class for Group & Project Object Builders.
      # This class is not intended to be used on its own but
      # rather inherited from.
      #
      # Cache keeps 1000 entries at most, 1000 is chosen based on:
      #    - one cache entry uses around 0.5K memory, 1000 items uses around 500K.
      #      (leave some buffer it should be less than 1M). It is afforable cost for project import.
      #    - for projects in Gitlab.com, it seems 1000 entries for labels/milestones is enough.
      #      For example, gitlab has ~970 labels and 26 milestones.
      LRU_CACHE_SIZE = 1000

      class ObjectBuilder
        def self.build(...)
          new(...).find
        end

        def initialize(klass, attributes)
          @klass = klass.ancestors.include?(Label) ? Label : klass
          @attributes = attributes

          if Gitlab::SafeRequestStore.active?
            @lru_cache = cache_from_request_store
            @cache_key = [klass, attributes]
          end
        end

        def find
          find_with_cache do
            find_object || create_object
          end
        end

        protected

        def create_object
          klass.transaction do
            case klass.to_s
            when 'Epic'
              klass.new(prepare_attributes)
            else
              klass.create(prepare_attributes)
            end
          end
        end

        def where_clauses
          raise NotImplementedError
        end

        # attributes wrapped in a method to be
        # adjusted in sub-class if needed
        def prepare_attributes
          attributes
        end

        def find_with_cache(key = cache_key)
          return yield unless lru_cache && key

          lru_cache[key] ||= yield
        end

        private

        attr_reader :klass, :attributes, :lru_cache, :cache_key

        def cache_from_request_store
          Gitlab::SafeRequestStore[:lru_cache] ||= LruRedux::Cache.new(LRU_CACHE_SIZE)
        end

        def find_object
          klass.find_by(where_clause)
        end

        def where_clause
          where_clauses.reduce(:and)
        end

        def table
          @table ||= klass.arel_table
        end

        # Returns Arel clause:
        # `"{table_name}"."{attrs.keys[0]}" = '{attrs.values[0]} AND {table_name}"."{attrs.keys[1]}" = '{attrs.values[1]}"`
        # from the given Hash of attributes.
        def attrs_to_arel(attrs)
          attrs.map do |key, value|
            table[key].eq(value)
          end.reduce(:and)
        end

        # Returns Arel clause `"{table_name}"."title" = '{attributes['title']}'`
        # if attributes has 'title key, otherwise `nil`.
        def where_clause_for_title
          attrs_to_arel(attributes.slice('title'))
        end

        # Returns Arel clause `"{table_name}"."description" = '{attributes['description']}'`
        # if attributes has 'description key, otherwise `nil`.
        def where_clause_for_description
          attrs_to_arel(attributes.slice('description'))
        end

        # Returns Arel clause `"{table_name}"."created_at" = '{attributes['created_at']}'`
        # if attributes has 'created_at key, otherwise `nil`.
        def where_clause_for_created_at
          attrs_to_arel(attributes.slice('created_at'))
        end
      end
    end
  end
end
