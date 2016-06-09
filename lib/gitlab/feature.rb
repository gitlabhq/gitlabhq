module Gitlab
  # Module for checking if certain features are enabled or not.
  #
  # To check for a feature you can use an "enabled?" method generated for each
  # registered feature:
  #
  #     if Gitlab::Feature.updating_notes_enabled?
  #       ...
  #     end
  #
  # ## Adding Features
  #
  # Adding features works in two simple steps:
  #
  # 1. Add the feature name to the FEATURES array below
  # 2. Add a migration that adds a column called "enable_FEATURE" (where
  #    "FEATURE" is the name of your feature) to "application_settings". The
  #    type should be a boolean with a default value of true.
  module Feature
    extend CurrentSettings

    FEATURES = [
      :toggling_award_emoji,
      :creating_notes,
      :updating_notes,
      :removing_notes,
      :removing_note_attachments
    ].freeze

    class << self
      FEATURES.each do |feature|
        define_method("#{feature}_enabled?") do
          feature_enabled?(feature)
        end
      end

      # Returns true if the given feature is enabled.
      def feature_enabled?(feature)
        settings = current_application_settings
        method = column_name(feature)

        # If a feature column doesn't exist we still want to enable the
        # feature. This for example allows the use of a fake application
        # settings object without having to duplicate any feature related
        # logic there.
        return true unless settings.respond_to?(method)

        settings.__send__(method)
      end

      # Returns a Hash containing all features and the corresponding column
      # names.
      def features_with_columns
        FEATURES.each_with_object({}) do |feature, hash|
          hash[feature] = column_name(feature)
        end
      end

      # Returns the names of the columns.
      def column_names
        FEATURES.map { |f| column_name(f) }
      end

      # Returns the column name for a feature.
      def column_name(feature)
        :"enable_#{feature}"
      end
    end
  end
end
