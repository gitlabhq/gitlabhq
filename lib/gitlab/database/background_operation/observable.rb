# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module Observable
        extend ActiveSupport::Concern

        def prometheus_labels
          @prometheus_labels ||= {
            migration_id: format("%s/%s", *id),
            migration_identifier: format("%s/%s.%s", job_class_name, table_name, column_name)
          }
        end
      end
    end
  end
end
