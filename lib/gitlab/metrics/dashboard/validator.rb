# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Validator
        DASHBOARD_SCHEMA_PATH = Rails.root.join(*%w[lib gitlab metrics dashboard validator schemas dashboard.json]).freeze

        class << self
          def validate(content, schema_path = DASHBOARD_SCHEMA_PATH, dashboard_path: nil, project: nil)
            errors(content, schema_path, dashboard_path: dashboard_path, project: project).empty?
          end

          def validate!(content, schema_path = DASHBOARD_SCHEMA_PATH, dashboard_path: nil, project: nil)
            errors = errors(content, schema_path, dashboard_path: dashboard_path, project: project)
            errors.empty? || raise(errors.first)
          end

          def errors(content, schema_path = DASHBOARD_SCHEMA_PATH, dashboard_path: nil, project: nil)
            Validator::Client
              .new(content, schema_path, dashboard_path: dashboard_path, project: project)
              .execute
          end
        end
      end
    end
  end
end
