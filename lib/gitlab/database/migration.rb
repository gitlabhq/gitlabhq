# frozen_string_literal: true

module Gitlab
  module Database
    class Migration
      module LockRetriesConcern
        extend ActiveSupport::Concern

        class_methods do
          def enable_lock_retries!
            @enable_lock_retries = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
          end

          def enable_lock_retries?
            @enable_lock_retries
          end
        end

        delegate :enable_lock_retries?, to: :class
      end

      # This implements a simple versioning scheme for migration helpers.
      #
      # We need to be able to version helpers, so we can change their behavior without
      # altering the behavior of already existing migrations in incompatible ways.
      #
      # We can continue to change the behavior of helpers without bumping the version here,
      # *if* the change is backwards-compatible.
      #
      # If not, we would typically override the helper method in a new MigrationHelpers::V[0-9]+
      # class and create a new entry with a bumped version below.
      #
      # We use major version bumps to indicate significant changes and minor version bumps
      # to indicate backwards-compatible or otherwise minor changes (e.g. a Rails version bump).
      # However, this hasn't been strictly formalized yet.
      MIGRATION_CLASSES = {
        1.0 => Class.new(ActiveRecord::Migration[6.1]) do
          include LockRetriesConcern
          include Gitlab::Database::MigrationHelpers::V2
        end
      }.freeze

      def self.[](version)
        MIGRATION_CLASSES[version] || raise(ArgumentError, "Unknown migration version: #{version}")
      end

      # The current version to be used in new migrations
      def self.current_version
        1.0
      end
    end
  end
end
