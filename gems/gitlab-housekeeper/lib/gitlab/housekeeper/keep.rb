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
      # This can be done in the `each_identified_change` method like:
      # ```
      # next unless matches_filter_identifiers?(change.identifiers)
      # ... do the computation heavy work and yield change object.
      # ```
      def matches_filter_identifiers?(identifiers)
        return true unless filter_identifiers

        filter_identifiers.matches_filters?(identifiers)
      end

      # The each_identified_change method should search the codebase to find potential changes based on the specific
      # intention of the keep. It only needs to construct and yield a Change object with `identifiers` and `context`.
      # This method should NOT perform file modifications or other side effects.
      # All actual changes should be implemented in the make_change method.
      #
      # @yieldparam [Gitlab::Housekeeper::Change]
      def each_identified_change
        raise NotImplementedError, "A Keep must implement each_identified_change method"
      end

      # The make_change method performs the actual file modifications and prepares the final Change object.
      # This method receives a Change object from each_identified_change and should:
      # - Perform all file modifications and side effects
      # - Set the final change details (title, description, changed_files, etc.)
      # - Return the completed Change object, or nil if no changes should be made
      #
      # @param [Gitlab::Housekeeper::Change] change The change object with context from each_change
      def make_change!(change)
        raise NotImplementedError, "A Keep must implement make_change method"
      end

      private

      attr_reader :logger
    end
  end
end
