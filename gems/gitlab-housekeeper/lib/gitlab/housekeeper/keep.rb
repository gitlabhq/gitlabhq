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
      def initialize(logger: nil)
        @logger = logger || Logger.new(nil)
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
    end
  end
end
