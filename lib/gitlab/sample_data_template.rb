# frozen_string_literal: true

module Gitlab
  class SampleDataTemplate < ProjectTemplate
    class << self
      def localized_templates_table
        [
          SampleDataTemplate.new('basic', 'Basic', _('Basic Sample Data template with Issues, Merge Requests and Milestones.'), 'https://gitlab.com/gitlab-org/sample-data-templates/basic'),
          SampleDataTemplate.new('serenity_valley', 'Serenity Valley', _('Serenity Valley Sample Data template.'), 'https://gitlab.com/gitlab-org/sample-data-templates/serenity-valley')
        ].freeze
      end

      def all
        localized_templates_table
      end

      def archive_directory
        Rails.root.join("vendor/sample_data_templates")
      end
    end
  end
end
