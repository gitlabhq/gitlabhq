# frozen_string_literal: true

module Ci
  ##
  # This module implements methods that need to read and write
  # metadata for CI/CD entities.
  #
  module Metadatable
    extend ActiveSupport::Concern

    included do
      has_one :metadata,
        ->(build) { where(partition_id: build.partition_id) },
        class_name: 'Ci::BuildMetadata',
        foreign_key: :build_id,
        partition_foreign_key: :partition_id,
        inverse_of: :build,
        autosave: true

      accepts_nested_attributes_for :metadata

      delegate :timeout, to: :metadata, prefix: true, allow_nil: true
      delegate :interruptible, to: :metadata, prefix: false, allow_nil: true
      delegate :environment_auto_stop_in, to: :metadata, prefix: false, allow_nil: true
      delegate :set_cancel_gracefully, to: :metadata, prefix: false, allow_nil: false
      delegate :id_tokens, to: :metadata, allow_nil: true
      delegate :exit_code, to: :metadata, allow_nil: true

      before_validation :ensure_metadata, on: :create

      scope :with_project_and_metadata, -> do
        joins(:metadata).includes(:metadata).preload(:project)
      end
    end

    def has_exposed_artifacts?
      !!metadata&.has_exposed_artifacts?
    end

    def cancel_gracefully?
      !!metadata&.cancel_gracefully?
    end

    def ensure_metadata
      metadata || build_metadata(project: project)
    end

    def degenerated?
      self.options.blank?
    end

    def degenerate!
      self.class.transaction do
        self.update!(options: nil, yaml_variables: nil)
        self.needs.all.delete_all
        self.metadata&.destroy
        yield if block_given?
      end
    end

    def options
      read_metadata_attribute(:options, :config_options, {})
    end

    def yaml_variables
      read_metadata_attribute(:yaml_variables, :config_variables, [])
    end

    def options=(value)
      write_metadata_attribute(:options, :config_options, value)

      ensure_metadata.tap do |metadata|
        # Store presence of exposed artifacts in build metadata to make it easier to query
        metadata.has_exposed_artifacts = value&.dig(:artifacts, :expose_as).present?
        metadata.environment_auto_stop_in = value&.dig(:environment, :auto_stop_in)
      end
    end

    def yaml_variables=(value)
      write_metadata_attribute(:yaml_variables, :config_variables, value)
    end

    def interruptible
      metadata&.interruptible
    end

    def interruptible=(value)
      ensure_metadata.interruptible = value
    end

    def id_tokens?
      metadata&.id_tokens.present?
    end

    def id_tokens=(value)
      ensure_metadata.id_tokens = value
    end

    def enqueue_immediately?
      !!options[:enqueue_immediately]
    end

    def set_enqueue_immediately!
      # ensures that even if `config_options: nil` in the database we set the
      # new value correctly.
      self.options = options.merge(enqueue_immediately: true)
    end

    private

    def read_metadata_attribute(legacy_key, metadata_key, default_value = nil)
      read_attribute(legacy_key) || metadata&.read_attribute(metadata_key) || default_value
    end

    def write_metadata_attribute(legacy_key, metadata_key, value)
      ensure_metadata.write_attribute(metadata_key, value)
      write_attribute(legacy_key, nil)
    end
  end
end

Ci::Metadatable.prepend_mod_with('Ci::Metadatable')
