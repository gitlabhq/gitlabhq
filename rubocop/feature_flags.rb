# frozen_string_literal: true

module RuboCop
  module FeatureFlags
    FEATURE_CALLERS = %w[Feature FeatureFlags Gitlab::AiGateway].freeze
    FEATURE_METHODS = %i[enabled? disabled? push_feature_flag].freeze

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

    class << self
      def feature_flag_name(node)
        return unless trackable_flag?(node)

        flag_arg = flag_arg(node)
        flag_value = flag_value(node)
        return unless flag_value

        return unless flag_arg.type?(:str, :sym)

        if caller_is_feature_gitaly?(node)
          "gitaly_#{flag_value}"
        elsif caller_is_feature_kas?(node)
          "kas_#{flag_value}"
        else
          flag_value
        end
      end

      def dynamic_feature_flag_names(node)
        return [] unless trackable_flag?(node)

        flag_arg = flag_arg(node)
        return [] unless flag_arg
        return [] unless flag_arg.type?(:dstr, :dsym)

        feature_flag_names = []
        str_prefix = flag_arg.children[0]
        rest_children = flag_arg.children[1..]

        if !str_prefix.str_type?
          puts_if_debug(node, "Interpolated feature flag name has non-string first part, we won't track it.")
        elsif rest_children.none?(&:str_type?)
          matching_feature_flags = all_feature_flag_names.select { |flag| flag.start_with?(str_prefix.value) }
          matching_feature_flags.each do |matching_feature_flag|
            puts_if_debug(node,
              "Returning '#{matching_feature_flag}', as this feature flag starts with '#{str_prefix.value}'.")
            feature_flag_names << matching_feature_flag
          end
        else
          puts_if_debug(node, "Interpolated feature flag name has multiple static string parts, we won't track it.")
        end

        feature_flag_names
      end

      def all_feature_flag_names
        @all_feature_flag_names ||= load_feature_flags('config/feature_flags/**/*.yml') +
          ee_feature_flag_names +
          jh_feature_flag_names
      end

      def ee_feature_flag_names
        @ee_feature_flag_names ||= load_feature_flags('ee/config/feature_flags/**/*.yml')
      end

      def jh_feature_flag_names
        @jh_feature_flag_names ||= load_feature_flags('jh/config/feature_flags/**/*.yml')
      end

      private

      def load_feature_flags(pattern)
        flags_path = File.expand_path("../#{pattern}", __dir__)
        Dir.glob(flags_path).map do |path|
          File.basename(path, '.yml')
        end
      end

      def trackable_flag?(node)
        feature_method?(node) || self_method?(node) || worker_method?(node)
      end

      def feature_method?(node)
        return false unless FEATURE_METHODS.include?(method_name(node))

        caller_is_feature?(node) || caller_is_feature_gitaly?(node) || caller_is_feature_kas?(node)
      end

      def self_method?(node)
        SELF_METHODS.include?(method_name(node)) && class_caller(node).empty?
      end

      def worker_method?(node)
        WORKER_METHODS.include?(method_name(node))
      end

      def caller_is_feature?(node)
        FEATURE_CALLERS.detect do |caller|
          class_caller(node) == caller || class_caller(node).end_with?("::#{caller}")
        end
      end

      def caller_is_feature_gitaly?(node)
        class_caller(node) == "Feature::Gitaly"
      end

      def caller_is_feature_kas?(node)
        class_caller(node) == "Feature::Kas"
      end

      def puts_if_debug(node, text)
        return unless RuboCop::ConfigLoader.debug

        warn "#{text} (call: `#{node.source}`, source: #{node.source_range.source_buffer.name})"
      end

      def method_name(node)
        node.children[1]
      end

      def class_caller(node)
        node.children[0]&.const_name.to_s
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
    end
  end
end
