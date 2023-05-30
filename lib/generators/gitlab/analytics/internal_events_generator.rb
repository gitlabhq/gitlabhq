# frozen_string_literal: true

require 'rails/generators'

module Gitlab
  module Analytics
    class InternalEventsGenerator < Rails::Generators::Base
      TIME_FRAME_DIRS = {
        '7d' => 'counts_7d',
        '28d' => 'counts_28d'
      }.freeze

      TIME_FRAMES_DEFAULT = TIME_FRAME_DIRS.keys.tap do |time_frame_defaults|
        time_frame_defaults.class_eval do
          def to_s
            join(", ")
          end
        end
      end.freeze

      ALLOWED_TIERS = %w[free premium ultimate].dup.tap do |tiers_default|
        tiers_default.class_eval do
          def to_s
            join(", ")
          end
        end
      end.freeze

      TOP_LEVEL_DIR = 'config'
      TOP_LEVEL_DIR_EE = 'ee'
      DESCRIPTION_MIN_LENGTH = 50
      KNOWN_EVENTS_PATH = 'lib/gitlab/usage_data_counters/known_events/common.yml'
      KNOWN_EVENTS_PATH_EE = 'ee/lib/ee/gitlab/usage_data_counters/known_events/common.yml'

      source_root File.expand_path('../../../../generator_templates/gitlab_internal_events', __dir__)

      desc 'Generates metric definitions yml files and known events entries'

      class_option :skip_namespace,
        hide: true
      class_option :skip_collision_check,
        hide: true
      class_option :time_frames,
        optional: true,
        default: TIME_FRAMES_DEFAULT,
        type: :array,
        banner: TIME_FRAMES_DEFAULT,
        desc: "Indicates the metrics time frames. Please select one or more from: #{TIME_FRAMES_DEFAULT}"
      class_option :tiers,
        optional: true,
        default: ALLOWED_TIERS,
        type: :array,
        banner: ALLOWED_TIERS,
        desc: "Indicates the metric's GitLab subscription tiers. Please select one or more from: #{ALLOWED_TIERS}"
      class_option :group,
        type: :string,
        optional: false,
        desc: 'Name of group that added this metric'
      class_option :stage,
        type: :string,
        optional: false,
        desc: 'Name of stage that added this metric'
      class_option :section,
        type: :string,
        optional: false,
        desc: 'Name of section that added this metric'
      class_option :mr,
        type: :string,
        optional: false,
        desc: 'Merge Request that adds this metric'
      class_option :event,
        type: :string,
        optional: false,
        desc: 'Name of the event that this metric counts'
      class_option :unique_on,
        type: :string,
        optional: false,
        desc: 'Name of the event property that this metric counts'

      def create_metric_file
        validate!

        time_frames.each do |time_frame|
          template "metric_definition.yml",
            file_path(time_frame),
            key_path(time_frame),
            time_frame,
            ask_description(time_frame)
        end

        # ToDo: Delete during https://gitlab.com/groups/gitlab-org/-/epics/9542 cleanup
        append_file known_events_file_name, known_event_entry
      end

      private

      def known_event_entry
        <<~YML
          - name: #{options[:event]}
            aggregation: weekly
        YML
      end

      def ask_description(time_frame)
        question = <<~DESC
          Please describe in at least #{DESCRIPTION_MIN_LENGTH} characters
          what #{key_path(time_frame)} metric represents,
          consider mentioning: events, and event attributes in the description.
          your answer will be processed to power a full-text search tool and help others find and reuse this metric.
        DESC

        say("")
        description = ask(question)

        while description.length < DESCRIPTION_MIN_LENGTH
          error_mgs = <<~ERROR
            Provided description is to short: #{description.length} of required #{DESCRIPTION_MIN_LENGTH} characters
          ERROR

          say(set_color(error_mgs), :red)

          description = ask("Please provide description that is #{DESCRIPTION_MIN_LENGTH} characters long.\n")
        end
        description
      end

      def distribution
        content = [
          free? ? "- ce" : nil,
          "- ee"
        ].compact.join("\n")

        "distribution:\n#{content}"
      end

      def tier
        "tier:\n- #{options[:tiers].join("\n- ")}"
      end

      def milestone
        Gitlab::VERSION.match('(\d+\.\d+)').captures.first
      end

      def class_name
        'RedisHLLMetric'
      end

      def key_path(time_frame)
        "count_distinct_#{options[:unique_on]}_from_#{options[:event]}_#{time_frame}"
      end

      def file_path(time_frame)
        path = File.join(TOP_LEVEL_DIR, 'metrics', TIME_FRAME_DIRS[time_frame], "#{key_path(time_frame)}.yml")
        path = File.join(TOP_LEVEL_DIR_EE, path) unless free?
        path
      end

      def known_events_file_name
        (free? ? KNOWN_EVENTS_PATH : KNOWN_EVENTS_PATH_EE)
      end

      def validate!
        raise "Required file: #{known_events_file_name} does not exists." unless File.exist?(known_events_file_name)

        validate_tiers!

        %i[unique_on event mr section stage group].each do |option|
          raise "The option: --#{option} is  missing" unless options.key? option
        end

        time_frames.each do |time_frame|
          validate_time_frame!(time_frame)
          validate_key_path!(time_frame)
        end
      end

      def validate_time_frame!(time_frame)
        return if TIME_FRAME_DIRS.key?(time_frame)

        raise "Invalid time frame: #{time_frame}, allowed options are: #{TIME_FRAMES_DEFAULT}"
      end

      def validate_tiers!
        wrong_tiers = options[:tiers] - ALLOWED_TIERS
        unless wrong_tiers.empty?
          raise "Tiers option included not allowed values: #{wrong_tiers}. Only allowed values are: #{ALLOWED_TIERS}"
        end

        return unless options[:tiers].empty?

        raise "At least one tier must be present. Please set --tiers option"
      end

      def validate_key_path!(time_frame)
        return unless metric_definition_exists?(time_frame)

        raise "Metric definition with key path '#{key_path(time_frame)}' already exists"
      end

      def free?
        options[:tiers].include? "free"
      end

      def time_frames
        options[:time_frames]
      end

      def directory
        @directory ||= TIME_FRAME_DIRS.find { |d| d.match?(input_dir) }
      end

      def metric_definitions
        @definitions ||= Gitlab::Usage::MetricDefinition.definitions(skip_validation: true)
      end

      def metric_definition_exists?(time_frame)
        metric_definitions[key_path(time_frame)].present?
      end
    end
  end
end
