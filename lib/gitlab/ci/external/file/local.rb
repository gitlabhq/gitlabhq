# frozen_string_literal: true

module Gitlab
  module Ci
    module External
      module File
        class Local < Base
          attr_reader :location, :project, :sha, :ignore_if_missing

          def initialize(location, opts = {})
            super

            @project = opts.fetch(:project)
            @sha = opts.fetch(:sha)
            @ignore_if_missing = opts.fetch(:ignore_if_missing)
          end

          def content
            @content ||= fetch_local_content
          end

          def error_message
            "Local file '#{location}' is not valid."
          end

          private

          def fetch_local_content
            content = project.repository.blob_data_at(sha, location)

            if content.nil? && @ignore_if_missing
              return '{}'
            end

            content
          end
        end
      end
    end
  end
end
