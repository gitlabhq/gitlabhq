# frozen_string_literal: true

module Ci
  ##
  # This module implements methods that need to read and write
  # metadata for CI/CD entities.
  #
  module Metadatable
    extend ActiveSupport::Concern

    included do
      has_one :metadata, class_name: 'Ci::BuildMetadata',
                         foreign_key: :build_id,
                         inverse_of: :build,
                         autosave: true

      delegate :timeout, to: :metadata, prefix: true, allow_nil: true
      before_create :ensure_metadata
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
    end

    def yaml_variables=(value)
      write_metadata_attribute(:yaml_variables, :config_variables, value)
    end

    private

    def read_metadata_attribute(legacy_key, metadata_key, default_value = nil)
      read_attribute(legacy_key) || metadata&.read_attribute(metadata_key) || default_value
    end

    def write_metadata_attribute(legacy_key, metadata_key, value)
      # save to metadata or this model depending on the state of feature flag
      if Feature.enabled?(:ci_build_metadata_config)
        ensure_metadata.write_attribute(metadata_key, value)
        write_attribute(legacy_key, nil)
      else
        write_attribute(legacy_key, value)
        metadata&.write_attribute(metadata_key, nil)
      end
    end
  end
end
