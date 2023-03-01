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

    def create_event_file
      raise "Event definition already exists at #{file_path}" if definition_exists?

      template "event_definition.yml", file_path, force: false
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

    # Example of file name
    # 20230227000018_project_management_issue_title_changed.yml
    def file_name
      name = remove_special_chars("#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_#{event_category}_#{event_action}")
      "#{name[0..95]}.yml" # max 100 chars, see https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/2030#note_679501200
    end

    def remove_special_chars(input)
      input.gsub("::", "__").gsub(/[^A-Za-z0-9_]/, '')
    end
  end
end
