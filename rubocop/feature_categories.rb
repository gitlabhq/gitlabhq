# frozen_string_literal: true

require 'set'
require 'yaml'
require 'digest/sha2'

module RuboCop
  module FeatureCategories
    CONFIG_PATH = File.expand_path("../config/feature_categories.yml", __dir__)

    # List of feature categories which are not defined in config/feature_categories.yml
    # https://docs.gitlab.com/ee/development/feature_categorization/#tooling-feature-category
    # https://docs.gitlab.com/ee/development/feature_categorization/#shared-feature-category
    CUSTOM_CATEGORIES = %w[
      tooling
      shared
    ].to_set.freeze

    def self.available
      @available ||= YAML.load_file(CONFIG_PATH).to_set
    end

    def self.available_with_custom
      @available_with_custom ||= available.union(CUSTOM_CATEGORIES)
    end

    # Used by RuboCop to invalidate its cache if the contents of
    # config/feature_categories.yml changes.
    # Define a method called `external_dependency_checksum` and call
    # this method to use it.
    def self.config_checksum
      @config_checksum ||= Digest::SHA256.file(CONFIG_PATH).hexdigest
    end
  end
end
