# frozen_string_literal: true

module ActiveRecord
  module FixedItemsModel
    # Includes handy AR-like methods to models that have a fixed set
    # of items that are stored in code instead of the database.
    #
    # See ActiveRecord::FixedItemsModel::HasOne for reference
    # on how to build associations.
    #
    # A minimal example of such a model is:
    #
    # class StaticModel
    #   include ActiveModel::Model
    #   include ActiveModel::Attributes
    #   include ActiveRecord::FixedItemsModel::Model
    #
    #   ITEMS = [
    #     {
    #       id: 1,
    #       name: 'To do'
    #     }
    #   ]
    #
    #   attribute :id, :integer
    #   attribute :name, :string
    # end
    #
    # Usage:
    #
    # StaticModel.find(1)
    # StaticModel.where(name: 'To do')
    # StaticModel.find_by(name: 'To do')
    # StaticModel.all
    #
    module Model
      extend ActiveSupport::Concern

      class_methods do
        # Caches created instances for fast retrieval used in associations.
        def find(id)
          id = id.to_i

          find_instances[id] ||= self::ITEMS.find { |item| item[:id] == id }&.then do |item_data|
            new(item_data)
          end
        end

        def all
          self::ITEMS.map { |data| new(data) }
        end

        def where(**conditions)
          all.select { |item| item.matches?(conditions) }
        end

        def find_by(**conditions)
          all.find { |item| item.matches?(conditions) }
        end

        private

        def find_instances
          @find_instances ||= []
        end
      end

      included do
        def matches?(conditions)
          conditions.all? do |attribute, value|
            if value.is_a?(Array)
              value.include?(read_attribute(attribute))
            else
              read_attribute(attribute) == value
            end
          end
        end

        def has_attribute?(key)
          attribute_names.include?(key.to_s)
        end

        def read_attribute(key)
          return nil unless has_attribute?(key)

          # Passed attributes are actual attributes of the model
          # rubocop:disable GitlabSecurity/PublicSend -- Reason above
          public_send(key)
          # rubocop:enable GitlabSecurity/PublicSend
        end

        def inspect
          "#<#{self.class} #{attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')}>"
        end

        def ==(other)
          super ||
            (other.instance_of?(self.class) && # Same exact class
              !id.nil? && # This object has an ID
              other.id == id) # Same ID
        end
        alias_method :eql?, :==

        def hash
          if id
            [self.class, id].hash
          else
            super  # Falls back to Object#hash for unsaved records
          end
        end
      end
    end
  end
end
