# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Local < Base
            extend ::Gitlab::Utils::Override
            include Gitlab::Utils::StrongMemoize

            def initialize(params, context)
              @location = params[:local]

              super
            end

            def content
              strong_memoize(:content) { fetch_local_content }
            end

            private

            def validate_content!
              if context.project&.repository.nil?
                errors.push("Local file `#{location}` does not have project!")
              elsif content.nil?
                errors.push("Local file `#{location}` does not exist!")
              elsif content.blank?
                errors.push("Local file `#{location}` is empty!")
              end
            end

            def fetch_local_content
              context.project.repository.blob_data_at(context.sha, location)
            end

            override :expand_context_attrs
            def expand_context_attrs
              {
                project: context.project,
                sha: context.sha,
                user: context.user,
                parent_pipeline: context.parent_pipeline
              }
            end
          end
        end
      end
    end
  end
end
