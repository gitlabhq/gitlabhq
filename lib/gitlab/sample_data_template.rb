# frozen_string_literal: true

module Gitlab
  class SampleDataTemplate < ProjectTemplate
    class << self
      def localized_templates_table
        [
          SampleDataTemplate.new('sample', 'Sample GitLab Project', _('Get started with a project that follows best practices for setting up GitLab for your own organization, including sample Issues, Merge Requests, and Milestones'), 'https://gitlab.com/gitlab-org/sample-data-templates/sample-gitlab-project')
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
