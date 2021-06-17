# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Gitlab
      # This cop tracks the usage of feature flags among the codebase.
      #
      # The files set in `tmp/feature_flags/*.used` can then be used for verification purpose.
      #
      class MarkUsedFeatureFlags < RuboCop::Cop::Cop
        include RuboCop::CodeReuseHelpers

        FEATURE_METHODS = %i[enabled? disabled?].freeze
        EXPERIMENTATION_METHODS = %i[active?].freeze
        EXPERIMENT_METHODS = %i[
          experiment
          experiment_enabled?
          push_frontend_experiment
        ].freeze
        RUGGED_METHODS = %i[
          use_rugged?
        ].freeze
        WORKER_METHODS = %i[
          data_consistency
          deduplicate
        ].freeze
        GRAPHQL_METHODS = %i[
          field
        ].freeze
        SELF_METHODS = %i[
          push_frontend_feature_flag
          limit_feature_flag=
        ].freeze + EXPERIMENT_METHODS + RUGGED_METHODS + WORKER_METHODS

        RESTRICT_ON_SEND = FEATURE_METHODS + EXPERIMENTATION_METHODS + GRAPHQL_METHODS + SELF_METHODS

        USAGE_DATA_COUNTERS_EVENTS_YAML_GLOBS = [
          File.expand_path("../../../config/metrics/aggregates/*.yml", __dir__),
          File.expand_path("../../../lib/gitlab/usage_data_counters/known_events/*.yml", __dir__)
        ].freeze

        DYNAMIC_FEATURE_FLAGS = [
          :usage_data_static_site_editor_commits, # https://gitlab.com/gitlab-org/gitlab/-/issues/284082
          :usage_data_static_site_editor_merge_requests # https://gitlab.com/gitlab-org/gitlab/-/issues/284083
        ].freeze

        # Called before all on_... have been called
        # When refining this method, always call `super`
        def on_new_investigation
          super
          track_dynamic_feature_flags!
          track_usage_data_counters_known_events!
        end

        def on_casgn(node)
          _, lhs_name, rhs = *node

          save_used_feature_flag(rhs.value) if lhs_name == :FEATURE_FLAG
        end

        def on_send(node)
          return if in_spec?(node)
          return unless trackable_flag?(node)

          flag_arg = flag_arg(node)
          flag_value = flag_value(node)
          return unless flag_value

          if flag_arg_is_str_or_sym?(node)
            if caller_is_feature_gitaly?(node)
              save_used_feature_flag("gitaly_#{flag_value}")
            else
              save_used_feature_flag(flag_value)
            end

            if experiment_method?(node) || experimentation_method?(node)
              # Additionally, mark experiment-related feature flag as used as well
              matching_feature_flags = defined_feature_flags.select { |flag| flag == "#{flag_value}_experiment_percentage" }
              matching_feature_flags.each do |matching_feature_flag|
                puts_if_ci(node, "The '#{matching_feature_flag}' feature flag tracks the #{flag_value} experiment, which is still in use, so we'll mark it as used.")
                save_used_feature_flag(matching_feature_flag)
              end
            end
          elsif flag_arg_is_send_type?(node)
            puts_if_ci(node, "Feature flag is dynamic: '#{flag_value}.")
          elsif flag_arg_is_dstr_or_dsym?(node)
            str_prefix = flag_arg.children[0]
            rest_children = flag_arg.children[1..]

            if rest_children.none? { |child| child.str_type? }
              matching_feature_flags = defined_feature_flags.select { |flag| flag.start_with?(str_prefix.value) }
              matching_feature_flags.each do |matching_feature_flag|
                puts_if_ci(node, "The '#{matching_feature_flag}' feature flag starts with '#{str_prefix.value}', so we'll optimistically mark it as used.")
                save_used_feature_flag(matching_feature_flag)
              end
            else
              puts_if_ci(node, "Interpolated feature flag name has multiple static string parts, we won't track it.")
            end
          else
            puts_if_ci(node, "Feature flag has an unknown type: #{flag_arg.type}.")
          end
        end

        private

        def puts_if_ci(node, text)
          puts "#{text} (call: `#{node.source}`, source: #{node.location.expression.source_buffer.name})" if ENV['CI']
        end

        def save_used_feature_flag(feature_flag_name)
          used_feature_flag_file = File.expand_path("../../../tmp/feature_flags/#{feature_flag_name}.used", __dir__)
          return if File.exist?(used_feature_flag_file)

          FileUtils.touch(used_feature_flag_file)
        end

        def class_caller(node)
          node.children[0]&.const_name.to_s
        end

        def method_name(node)
          node.children[1]
        end

        def flag_arg(node)
          if worker_method?(node)
            return unless node.children.size > 3

            node.children[3].each_pair.find do |pair|
              pair.key.value == :feature_flag
            end&.value
          elsif graphql_method?(node)
            return unless node.children.size > 3

            opts_index = node.children[3].hash_type? ? 3 : 4
            return unless node.children[opts_index]

            node.children[opts_index].each_pair.find do |pair|
              pair.key.value == :feature_flag
            end&.value
          else
            arg_index = rugged_method?(node) ? 3 : 2

            node.children[arg_index]
          end
        end

        def flag_value(node)
          flag_arg = flag_arg(node)
          return unless flag_arg

          if flag_arg.respond_to?(:value)
            flag_arg.value
          else
            flag_arg
          end.to_s.tr("\n/", ' _')
        end

        def flag_arg_is_str_or_sym?(node)
          flag_arg = flag_arg(node)
          flag_arg.str_type? || flag_arg.sym_type?
        end

        def flag_arg_is_send_type?(node)
          flag_arg(node).send_type?
        end

        def flag_arg_is_dstr_or_dsym?(node)
          flag = flag_arg(node)
          (flag.dstr_type? || flag.dsym_type?) && flag.children[0].str_type?
        end

        def caller_is_feature?(node)
          class_caller(node) == "Feature"
        end

        def caller_is_feature_gitaly?(node)
          class_caller(node) == "Feature::Gitaly"
        end

        def caller_is_experimentation?(node)
          class_caller(node) == "Gitlab::Experimentation"
        end

        def experiment_method?(node)
          EXPERIMENT_METHODS.include?(method_name(node))
        end

        def rugged_method?(node)
          RUGGED_METHODS.include?(method_name(node))
        end

        def feature_method?(node)
          FEATURE_METHODS.include?(method_name(node)) && (caller_is_feature?(node) || caller_is_feature_gitaly?(node))
        end

        def experimentation_method?(node)
          EXPERIMENTATION_METHODS.include?(method_name(node)) && caller_is_experimentation?(node)
        end

        def worker_method?(node)
          WORKER_METHODS.include?(method_name(node))
        end

        def graphql_method?(node)
          GRAPHQL_METHODS.include?(method_name(node)) && in_graphql_types?(node)
        end

        def self_method?(node)
          SELF_METHODS.include?(method_name(node)) && class_caller(node).empty?
        end

        def trackable_flag?(node)
          feature_method?(node) || experimentation_method?(node) || graphql_method?(node) || self_method?(node)
        end

        # Marking all event's feature flags as used as Gitlab::UsageDataCounters::HLLRedisCounter.track_event{,context}
        # is mostly used with dynamic event name.
        def track_dynamic_feature_flags!
          DYNAMIC_FEATURE_FLAGS.each(&method(:save_used_feature_flag))
        end

        # Marking all event's feature flags as used as Gitlab::UsageDataCounters::HLLRedisCounter.track_event{,context}
        # is mostly used with dynamic event name.
        def track_usage_data_counters_known_events!
          usage_data_counters_known_event_feature_flags.each(&method(:save_used_feature_flag))
        end

        def usage_data_counters_known_event_feature_flags
          USAGE_DATA_COUNTERS_EVENTS_YAML_GLOBS.each_with_object(Set.new) do |glob, memo|
            Dir.glob(glob).each do |path|
              YAML.safe_load(File.read(path))&.each do |hash|
                memo << hash['feature_flag'] if hash['feature_flag']
              end
            end
          end
        end

        def defined_feature_flags
          @defined_feature_flags ||= begin
            flags_paths = [
              'config/feature_flags/**/*.yml'
            ]

            # For EE additionally process `ee/` feature flags
            if File.exist?(File.expand_path('../../../ee/app/models/license.rb', __dir__)) && !%w[true 1].include?(ENV['FOSS_ONLY'].to_s)
              flags_paths << 'ee/config/feature_flags/**/*.yml'
            end

            flags_paths.each_with_object([]) do |flags_path, memo|
              flags_path = File.expand_path("../../../#{flags_path}", __dir__)
              Dir.glob(flags_path).each do |path|
                feature_flag_name = File.basename(path, '.yml')

                memo << feature_flag_name
              end
            end
          end
        end
      end
    end
  end
end
