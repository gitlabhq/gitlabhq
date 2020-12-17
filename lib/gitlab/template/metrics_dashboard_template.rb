# frozen_string_literal: true

module Gitlab
  module Template
    class MetricsDashboardTemplate < BaseTemplate
      def description
        "# This file is a template, and might need editing before it works on your project."
      end

      class << self
        def extension
          '.metrics-dashboard.yml'
        end

        def categories
          {
            "General" => ''
          }
        end

        def base_dir
          Rails.root.join('lib/gitlab/metrics/templates')
        end

        def finder(project = nil)
          Gitlab::Template::Finders::GlobalTemplateFinder.new(self.base_dir, self.extension, self.categories)
        end
      end
    end
  end
end
