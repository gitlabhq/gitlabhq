# frozen_string_literal: true

module ActiveRecord
  module FixedItemsModel
    RecordNotFound = Class.new(StandardError)
    UnknownAttribute = Class.new(StandardError)

    # Includes handy AR-like methods to models that have a fixed set
    # of items that are stored in code instead of the database.
    #
    # See ActiveRecord::FixedItemsModel::HasOne for reference
    # on how to build associations.
    #
    # A minimal example of such a model is:
    #
    # class StaticModel
    #   include ActiveRecord::FixedItemsModel::Model
    #
    #   ITEMS = [
    #     { id: 1, name: 'To do' }
    #   ].freeze
    #
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

      include ActiveModel::Model
      include ActiveModel::Attributes

      class_methods do
        def all
          load_items! if storage.empty?

          storage.compact
        end

        def find(id)
          find_by(id: id.to_i) || raise(RecordNotFound, "Couldn't find #{name} with 'id'=#{id}")
        end

        def find_by(**conditions)
          validate_attributes_exist!(conditions.keys)
          all.find { |item| item.matches?(conditions) }
        end

        def where(**conditions)
          validate_attributes_exist!(conditions.keys)
          all.select { |item| item.matches?(conditions) }
        end

        def storage
          @storage ||= []
        end

        private

        def load_items!
          validate_items_definition!

          self::ITEMS.each do |item_definition|
            item = new(item_definition)
            raise "Static definition in ITEMS is invalid! #{item.errors.full_messages.join(', ')}" unless item.valid?

            storage[item.id] = item
          end
        end

        def validate_items_definition!
          unique_ids = self::ITEMS.map { |item| item[:id] }.uniq

          return if unique_ids.size == self::ITEMS.size

          raise "Static definition ITEMS has #{self::ITEMS.size - unique_ids.size} duplicated IDs!"
        end

        def validate_attributes_exist!(attribute_names_to_check)
          invalid_attributes = attribute_names_to_check.reject { |attr| attribute_names.include?(attr.to_s) }

          return if invalid_attributes.empty?

          raise(UnknownAttribute, "Unknown attribute '#{invalid_attributes.first}' for #{name}")
        end
      end

      included do
        attribute :id, :integer

        validates :id, numericality: { greater_than: 0, only_integer: true }
      end

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

        # rubocop:disable GitlabSecurity/PublicSend -- Passed attributes are actual attributes of the model
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
          super # Falls back to Object#hash for unsaved records
        end
      end
    end
  end
end
