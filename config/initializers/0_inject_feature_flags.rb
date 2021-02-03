# frozen_string_literal: true

# This needs to be loaded after
# config/initializers/0_inject_enterprise_edition_module.rb

Feature.register_feature_groups
Feature.register_definitions
Feature.register_hot_reloader unless Rails.configuration.cache_classes
