# frozen_string_literal: true

module Gitlab
  module Housekeeper
    # A Keep is analogous to a Cop in RuboCop. The Keep is responsible for:
    # - Detecting a specific code change that should be made (eg. removing an old feature flag)
    # - Making the code change (eg. delete the feature flag YML file)
    # - Yielding a Change object that describes this change, For example:
    #   ```
    #   yield Gitlab::Housekeeper::Change.new(
    #     identifiers: ['remove-old-ff', 'old_ff_name'], # Unique and stable identifier for branch name
    #     title: "Remove old feature flag old_ff_name as it has been enabled since %15.0",
    #     description: "This feature flag was enabled in 15.0 and is not needed anymore ...",
    #     changed_files: ["config/feature_flags/ops/old_ff_name.yml", "app/models/user.rb"]
    #   )
    #   ```
    class Keep
      attr_reader :filter_identifiers

      def initialize(logger: nil, filter_identifiers: nil)
        @logger = logger || Logger.new(nil)
        @filter_identifiers = filter_identifiers
      end

      # This method is used to filter for each change at more granular level. For example:
      # - When we pass --filter-identifiers my_feature_flag,
      #   it should only create an MR specifically for my_feature_flag because
      #   we are having the feature flag name in the change.identifiers
      # Since the filtering logic is also implemented in the `Runner` class,
      # it is not required to use this in a keep, but it is recommended for
      # keeps which have expensive computation to perform. This is because
      # the Runner only gets the change object after the Keep has finished
      # computing the change.
      # This can be done in the `each_change` method like:
      # ```
      # next unless matches_filter_identifiers?(change.identifiers)
      # ... do the computation heavy work and yield change object.
      # ```
      def matches_filter_identifiers?(identifiers)
        return true unless filter_identifiers

        filter_identifiers.matches_filters?(identifiers)
      end

      # The each_change method must update local working copy files and yield a Change object which describes the
      # specific changed files and other data that will be used to generate a merge request. This is the core
      # implementation details for a specific housekeeper keep. This does not need to commit the changes or create the
      # merge request as that is handled by the gitlab-housekeeper gem.
      #
      # @yieldparam [Gitlab::Housekeeper::Change]
      def each_change
        raise NotImplementedError, "A Keep must implement each_change method"
      end

      private

      attr_reader :logger
    end
  end
end
