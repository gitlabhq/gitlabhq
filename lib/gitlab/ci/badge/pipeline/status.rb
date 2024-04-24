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
        end

        def entity
          'pipeline'
        end

        def status
          pipelines = @project.ci_pipelines.for_ref(@ref).order_id_desc
          pipelines = pipelines.without_statuses([:skipped]) if @ignore_skipped
          pipelines.pick(:status) || 'unknown'
        end

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
