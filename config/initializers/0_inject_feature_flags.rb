# This needs to be loaded after
# config/initializers/0_inject_enterprise_edition_module.rb

Feature.register_feature_groups
Feature.register_definitions
Feature.register_hot_reloader unless Rails.configuration.cache_classes

# This disallows usage of licensed feature names with the same name
# as feature flags. This naming collision creates confusion and it was
# decided to be removed in favor of explicit check.
# https://gitlab.com/gitlab-org/gitlab/-/issues/259611
if Gitlab.ee? && Gitlab.dev_or_test_env?
  # These are the names of feature flags that do violate the constraint of
  # being unique to licensed names. These feature flags should be reworked to
  # be "development" with explicit check
  IGNORED_FEATURE_FLAGS = %i[
    swimlanes
  ].to_set

  # First, we validate a list of overrides to ensure that these overrides
  # are removed if feature flag is gone
  missing_feature_flags = IGNORED_FEATURE_FLAGS.reject do |feature_flag|
    Feature::Definition.definitions[feature_flag]
  end

  if missing_feature_flags.any?
    raise "The following feature flags were added as an override for discovering licensed features. " \
          "Since these feature flags seems to be gone, ensure to remove them from \`IGNORED_FEATURE_FLAGS\` " \
          "in \`#{__FILE__}'`: #{missing_feature_flags.join(", ")}"
  end

  # Second, we validate that there's no feature flag under the name as licensed feature
  # flag, to ensure that the name used, is unique
  licensed_features = License::PLANS_BY_FEATURE.keys.select do |licensed_feature_name|
    IGNORED_FEATURE_FLAGS.exclude?(licensed_feature_name) &&
      Feature::Definition.definitions[licensed_feature_name]
  end

  if licensed_features.any?
    raise "The following feature flags do use a licensed feature. " \
          "To avoid the confusion between their usage it is disallowed to use feature flag " \
          "with exact the same name as licensed feature name. Use a different name to create " \
          "a distinction: #{licensed_features.join(", ")}"
  end
end
