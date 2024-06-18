# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Gitlab
      # This cop tracks the usage of feature flags among the codebase.
      #
      # The files set in `tmp/feature_flags/*.used` can then be used for verification purpose.
      #
      class MarkUsedFeatureFlags < RuboCop::Cop::Base
        include RuboCop::CodeReuseHelpers

        FEATURE_CALLERS = %w[Feature Config::FeatureFlags].freeze
        FEATURE_METHODS = %i[enabled? disabled?].freeze
        EXPERIMENT_METHODS = %i[
          experiment
        ].freeze
        WORKER_METHODS = %i[
          data_consistency
          deduplicate
        ].freeze
        SELF_METHODS = %i[
          push_frontend_feature_flag
          push_force_frontend_feature_flag
          limit_feature_flag=
          limit_feature_flag_for_override=
        ].freeze + EXPERIMENT_METHODS + WORKER_METHODS

        RESTRICT_ON_SEND = FEATURE_METHODS + SELF_METHODS

        class << self
          # We track feature flags in `on_new_investigation` only once per
          # rubocop whole run instead once per file.
          attr_accessor :feature_flags_already_tracked
        end

        # Called before all on_... have been called
        # When refining this method, always call `super`
        def on_new_investigation
          super

          return if self.class.feature_flags_already_tracked

          self.class.feature_flags_already_tracked = true
        end

        def on_casgn(node)
          _, lhs_name, rhs = *node

          save_used_feature_flag(rhs.value) if lhs_name.to_s.end_with?('FEATURE_FLAG')
        end

        def on_send(node)
          return if in_spec?(node)
          return unless trackable_flag?(node)

          flag_arg = flag_arg(node)
          flag_value = flag_value(node)
          return unless flag_value

          if flag_arg_is_str_or_sym?(flag_arg)
            if caller_is_feature_gitaly?(node)
              save_used_feature_flag("gitaly_#{flag_value}")
            else
              save_used_feature_flag(flag_value)
            end
          elsif flag_arg_is_send_type?(flag_arg)
            puts_if_debug(node, "Feature flag is dynamic: '#{flag_value}.")
          elsif flag_arg_is_dstr_or_dsym?(flag_arg)
            str_prefix = flag_arg.children[0]
            rest_children = flag_arg.children[1..]

            if rest_children.none? { |child| child.str_type? }
              matching_feature_flags = defined_feature_flags.select { |flag| flag.start_with?(str_prefix.value) }
              matching_feature_flags.each do |matching_feature_flag|
                puts_if_debug(node, "The '#{matching_feature_flag}' feature flag starts with '#{str_prefix.value}', so we'll optimistically mark it as used.")
                save_used_feature_flag(matching_feature_flag)
              end
            else
              puts_if_debug(node, "Interpolated feature flag name has multiple static string parts, we won't track it.")
            end
          else
            puts_if_debug(node, "Feature flag has an unknown type: #{flag_arg.type}.")
          end
        end

        private

        def puts_if_debug(node, text)
          return unless RuboCop::ConfigLoader.debug

          warn "#{text} (call: `#{node.source}`, source: #{node.location.expression.source_buffer.name})"
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
          else
            arg_index = 2

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

        def flag_arg_is_str_or_sym?(flag_arg)
          flag_arg.str_type? || flag_arg.sym_type?
        end

        def flag_arg_is_send_type?(flag_arg)
          flag_arg.send_type?
        end

        def flag_arg_is_dstr_or_dsym?(flag_arg)
          (flag_arg.dstr_type? || flag_arg.dsym_type?) && flag_arg.children[0].str_type?
        end

        def caller_is_feature?(node)
          FEATURE_CALLERS.detect do |caller|
            class_caller(node) == caller ||
              # Support detecting fully-defined callers based on nested detectable callers
              (caller.include?('::') && class_caller(node).end_with?(caller))
          end
        end

        def caller_is_feature_gitaly?(node)
          class_caller(node) == "Feature::Gitaly"
        end

        def feature_method?(node)
          FEATURE_METHODS.include?(method_name(node)) && (caller_is_feature?(node) || caller_is_feature_gitaly?(node))
        end

        def worker_method?(node)
          WORKER_METHODS.include?(method_name(node))
        end

        def self_method?(node)
          SELF_METHODS.include?(method_name(node)) && class_caller(node).empty?
        end

        def trackable_flag?(node)
          feature_method?(node) || self_method?(node) || worker_method?(node)
        end

        def defined_feature_flags
          @defined_feature_flags ||= begin
            flags_paths = [
              'config/feature_flags/**/*.yml'
            ]

            # For EE additionally process `ee/` feature flags
            if ee?
              flags_paths << 'ee/config/feature_flags/**/*.yml'
            end

            # For JH additionally process `jh/` feature flags
            if jh?
              flags_paths << 'jh/config/feature_flags/**/*.yml'
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
