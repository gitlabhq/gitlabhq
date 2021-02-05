# frozen_string_literal: true

module Gitlab::Ci
  module Badge
    module Pipeline
      ##
      # Pipeline status badge
      #
      class Status < Badge::Base
        attr_reader :project, :ref, :customization

        def initialize(project, ref, opts: {})
          @project = project
          @ref = ref
          @ignore_skipped = Gitlab::Utils.to_boolean(opts[:ignore_skipped], default: false)
          @customization = {
            key_width: opts[:key_width].to_i,
            key_text: opts[:key_text]
          }

          @sha = @project.commit(@ref).try(:sha)
        end

        def entity
          'pipeline'
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def status
          pipelines = @project.ci_pipelines
            .where(sha: @sha)

          relation = @ignore_skipped ? pipelines.without_statuses([:skipped]) : pipelines
          relation.latest_status(@ref) || 'unknown'
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def metadata
          @metadata ||= Pipeline::Metadata.new(self)
        end

        def template
          @template ||= Pipeline::Template.new(self)
        end
      end
    end
  end
end
