# frozen_string_literal: true

module ShaAttribute
  extend ActiveSupport::Concern

  class ShaAttributeTypeMismatchError < StandardError
    def initialize(column_name, column_type)
      @column_name = column_name
      @column_type = column_type
    end

    def message
      "sha_attribute :#{@column_name} should be a :binary column but it is :#{@column_type}"
    end
  end

  class Sha256AttributeTypeMismatchError < ShaAttributeTypeMismatchError
    def message
      "sha256_attribute :#{@column_name} should be a :binary column but it is :#{@column_type}"
    end
  end

  class_methods do
    def sha_attribute(name)
      return if Gitlab::Environment.static_verification?

      sha_attribute_fields << name

      attribute(name, Gitlab::Database::ShaAttribute.new)
    end

    def sha_attribute_fields
      @sha_attribute_fields ||= []
    end

    def sha256_attribute(name)
      return if Gitlab::Environment.static_verification?

      sha256_attribute_fields << name

      attribute(name, Gitlab::Database::Sha256Attribute.new)
    end

    def sha256_attribute_fields
      @sha256_attribute_fields ||= []
    end

    # This only gets executed in non-production environments as an additional check to ensure
    # the column is the correct type.  In production it should behave like any other attribute.
    # See https://gitlab.com/gitlab-org/gitlab/merge_requests/5502 for more discussion
    def load_schema!
      super

      return if Rails.env.production?

      sha_attribute_fields.each do |field|
        column = columns_hash[field.to_s]

        if column && column.type != :binary
          raise ShaAttributeTypeMismatchError.new(column.name, column.type)
        end
      end

      sha256_attribute_fields.each do |field|
        column = columns_hash[field.to_s]

        if column && column.type != :binary
          raise Sha256AttributeTypeMismatchError.new(column.name, column.type)
        end
      end
    end
  end
end

ShaAttribute::ClassMethods.prepend_mod_with('ShaAttribute')
