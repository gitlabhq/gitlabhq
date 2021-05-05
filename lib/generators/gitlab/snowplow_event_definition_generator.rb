# frozen_string_literal: true

require 'rails/generators'

module Gitlab
  class SnowplowEventDefinitionGenerator < Rails::Generators::Base
    CE_DIR = 'config/events'
    EE_DIR = 'ee/config/events'

    source_root File.expand_path('../../../generator_templates/snowplow_event_definition', __dir__)

    desc 'Generates an event definition yml file'

    class_option :ee, type: :boolean, optional: true, default: false, desc: 'Indicates if event is for ee'
    class_option :category, type: :string, optional: false, desc: 'Category of the event'
    class_option :action, type: :string, optional: false, desc: 'Action of the event'
    class_option :force, type: :boolean, optional: true, default: false, desc: 'Overwrite existing definition'

    def create_event_file
      raise "Event definition already exists at #{file_path}" if definition_exists? && !force_definition_override?

      template "event_definition.yml", file_path, force: force_definition_override?
    end

    def distributions
      (ee? ? ['- ee'] : ['- ce', '- ee']).join("\n")
    end

    def event_category
      options[:category]
    end

    def event_action
      options[:action]
    end

    def milestone
      Gitlab::VERSION.match('(\d+\.\d+)').captures.first
    end

    def ee?
      options[:ee]
    end

    def force_definition_override?
      options[:force]
    end

    private

    def definition_exists?
      File.exist?(ce_file_path) || File.exist?(ee_file_path)
    end

    def file_path
      ee? ? ee_file_path : ce_file_path
    end

    def ce_file_path
      File.join(CE_DIR, file_name)
    end

    def ee_file_path
      File.join(EE_DIR, file_name)
    end

    def file_name
      "#{event_category}_#{event_action}.yml".underscore.gsub("/", "__")
    end
  end
end
