# frozen_string_literal: true

module Sha256Attribute
  extend ActiveSupport::Concern

  class_methods do
    def sha256_attribute(name)
      return if ENV['STATIC_VERIFICATION']

      validate_binary_column_exists!(name) unless Rails.env.production?

      attribute(name, Gitlab::Database::Sha256Attribute.new)
    end

    # This only gets executed in non-production environments as an additional check to ensure
    # the column is the correct type.  In production it should behave like any other attribute.
    # See https://gitlab.com/gitlab-org/gitlab/merge_requests/5502 for more discussion
    def validate_binary_column_exists!(name)
      return unless database_exists?

      unless table_exists?
        warn "WARNING: sha256_attribute #{name.inspect} is invalid since the table doesn't exist - you may need to run database migrations"
        return
      end

      column = columns.find { |c| c.name == name.to_s }

      unless column
        warn "WARNING: sha256_attribute #{name.inspect} is invalid since the column doesn't exist - you may need to run database migrations"
        return
      end

      unless column.type == :binary
        raise ArgumentError, "sha256_attribute #{name.inspect} is invalid since the column type is not :binary"
      end
    rescue StandardError => error
      Gitlab::AppLogger.error "Sha256Attribute initialization: #{error.message}"
      raise
    end

    def database_exists?
      Gitlab::Database.main.exists?
    end
  end
end
