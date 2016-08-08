module Gitlab
  module Badge
    ##
    # Build badge
    #
    class Build
      delegate :key_text, :value_text, to: :template

      def initialize(project, ref)
        @project = project
        @ref = ref
        @sha = @project.commit(@ref).try(:sha)
      end

      def status
        @project.pipelines
          .where(sha: @sha, ref: @ref)
          .status || 'unknown'
      end

      def metadata
        @metadata ||= Build::Metadata.new(@project, @ref)
      end

      def template
        @template ||= Build::Template.new(status)
      end
    end
  end
end
