# frozen_string_literal: true

module Keeps
  module Prompts
    class RemoveFeatureFlags
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def fetch(feature_flag, file, flag_enabled)
        if file.end_with?('_spec.rb')
          prompt_rspec(feature_flag, file, flag_enabled)
        elsif file.end_with?('.rb')
          prompt_ruby(feature_flag, file, flag_enabled)
        elsif file.end_with?('.md')
          prompt_markdown(feature_flag, file)
        else
          logger.puts("Unexpected file extension in #{file} referencing feature flag #{feature_flag.name}. Skipping.")
        end
      end

      private

      def milestones_helper
        @milestones_helper ||= ::Keeps::Helpers::Milestones.new
      end

      def prompt_shared(feature_flag, file, flag_enabled)
        if flag_enabled
          <<~MARKDOWN
          Your job is to remove old feature flags from code. The feature flag has already been enabled and any references to it should be removed and any dead code paths that are only used when the feature flag is disabled should also be removed.
          The feature flag is called `#{feature_flag.name}`.
          The code below is in a file named `#{file}` and the code may contain references to the feature flag. It's possible this code does not contain explicit reference the feature flag. In that case make no changes.
          Once you are done with the changes make sure to run rubocop as well and reformat the code also remove any dead code and unreachable code that you see after the refactoring.
          MARKDOWN
        else
          <<~MARKDOWN
          Your job is to remove old feature flags from code. The feature flag has been disabled and any references to it should be removed and any dead code paths that are only used when the feature flag is enabled should also be removed.
          The feature flag is called `#{feature_flag.name}`.
          The code below is in a file named `#{file}` and the code may contain references to the feature flag. It's possible this code does not contain explicit reference the feature flag. In that case make no changes.
          Once you are done with the changes make sure to run rubocop as well and reformat the code also remove any dead code and unreachable code that you see after the refactoring.
          MARKDOWN
        end
      end

      def prompt_ruby(feature_flag, file, flag_enabled)
        <<~MARKDOWN
        #{prompt_shared(feature_flag, file, flag_enabled)}

        Feature flags are checked using `Feature.enabled?(:#{feature_flag.name})` and stubbed in tests using `stub_feature_flag(#{feature_flag.name}: false)`. If you see code that does not use the feature flag you should return the code unchanged exactly as it was.

        #{ruby_feature_flag_instructions(feature_flag, flag_enabled)}
        MARKDOWN
      end

      def ruby_feature_flag_instructions(feature_flag, flag_enabled)
        <<~MARKDOWN
        If you see a branch of logic with `if Feature.enabled?(:#{feature_flag.name})` you should simplify the logic assuming the check returns `#{flag_enabled}`. If you find a method that is returning `Feature.enabled?(:#{feature_flag.name})` then you should return `#{flag_enabled}` instead. You may also see `Feature.disabled?(:#{feature_flag.name})` and this is just the opposite of `enabled?` and you should assume this is always returning `#{!flag_enabled}`.
        MARKDOWN
      end

      def prompt_rspec(feature_flag, file, flag_enabled)
        <<~MARKDOWN
        #{prompt_ruby(feature_flag, file, flag_enabled)}

        #{rspec_instructions(flag_enabled)}
        MARKDOWN
      end

      def rspec_instructions(flag_enabled)
        <<~MARKDOWN
        Branches of tests that have stubbed the feature flag as #{!flag_enabled ? 'enabled' : 'disabled'} should be entirely removed. Pay close attention to the stubbed feature flag values to ensure you remove all redundant test coverage. Note that all feature flags are enabled by default in specs so you can assume branches without `stub_feature_flag` are behaving as though it is enabled. And if you find any branches of code that are calling `stub_feature_flag` for this feature flag and setting it to `true` you should simply remove the call to `stub_feature_flag` as it is redundant#{flag_enabled ? '' : ' also remove those blocks where the feature flag is enabled'}. You are likely to find whole rspec `context` blocks with the feature flag disabled. Be sure to #{flag_enabled ? 'delete' : 'keep'} the entire context block in that case.
        MARKDOWN
      end

      def prompt_markdown(feature_flag, file)
        <<~MARKDOWN
        #{prompt_shared(feature_flag, file, true)}

        When updating the markdown history notes you should not remove history notes that refer to the feature flag but instead just add a new history note. History notes start with `>- `. For this feature flag if you see existing history notes then you can add exactly this history note:

        ```
        > - [Generally available](#{feature_flag.rollout_issue_url}) in GitLab #{milestones_helper.next_milestone}. Feature flag `#{feature_flag.name}` removed.
        ```

        Other markdown references that refer to this feature flag, aside from history notes, can just be removed.
        MARKDOWN
      end
    end
  end
end
