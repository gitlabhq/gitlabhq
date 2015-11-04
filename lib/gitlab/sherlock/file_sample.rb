module Gitlab
  module Sherlock
    class FileSample
      attr_reader :id, :file, :line_samples, :events, :duration

      def initialize(file, line_samples, duration, events)
        @id = SecureRandom.uuid
        @file = file
        @line_samples = line_samples
        @duration = duration
        @events = events
      end

      def relative_path
        @relative_path ||= @file.gsub(/^#{Rails.root.to_s}\/?/, '')
      end

      def to_param
        @id
      end

      def source
        @source ||= File.read(@file)
      end
    end
  end
end
