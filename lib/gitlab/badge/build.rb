module Gitlab
  module Badge
    ##
    # Build badge
    #
    class Build
      def initialize(project, ref)
        @image = ::Ci::ImageForBuildService.new.execute(project, ref: ref)
      end

      def to_s
        @image[:name].sub(/\.svg$/, '')
      end

      def type
        'image/svg+xml'
      end

      def data
        File.read(@image[:path])
      end
    end
  end
end
