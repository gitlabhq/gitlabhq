module Gitlab
  module Badge
    ##
    # Build badge
    #
    class Build
      def initialize(project, ref)
        @project, @ref = project, ref
        @image = ::Ci::ImageForBuildService.new.execute(project, ref: ref)
      end

      def metadata
        Build::Metadata.new(@project, @ref)
      end

      def type
        'image/svg+xml'
      end

      def data
        File.read(@image[:path])
      end

      def to_s
        @image[:name].sub(/\.svg$/, '')
      end
    end
  end
end
