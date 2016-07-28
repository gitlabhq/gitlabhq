module Gitlab
  module Badge
    ##
    # Build badge
    #
    class Build
      def initialize(project, ref)
        @project = project
        @ref = ref
      end

      def status
        sha = @project.commit(@ref).try(:sha)

        @project.pipelines
          .where(sha: sha, ref: @ref)
          .status || 'unknown'
      end

      def metadata
        Build::Metadata.new(@project, @ref)
      end

      def template
        Build::Template.new(status)
      end

      def type
        'image/svg+xml'
      end

      def data
        File.read(
          Rails.root.join('public/ci', 'build-' + status + '.svg')
        )
      end
    end
  end
end
