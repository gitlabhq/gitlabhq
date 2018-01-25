module Gitlab
  module Ci
    class Trace
      attr_reader :job

      class << self
        def fabricate!(job)
          Gitlab::Ci::Trace.const_get(self.type(job)).new(@job)
        end

        def type(job)
          if job.complete? && job.job_artifacts_trace.exists?
            'Full'
          elsif job.running?
            'Live'
          else
            'Undefined'
          end
        end
      end

      def initialize(job)
        @job = job
      end

      def html(last_lines: nil)
        read do |stream|
          stream.html(last_lines: last_lines)
        end
      end

      def raw(last_lines: nil)
        read do |stream|
          stream.raw(last_lines: last_lines)
        end
      end

      def extract_coverage(regex)
        read do |stream|
          stream.extract_coverage(regex)
        end
      end

      def extract_sections
        read do |stream|
          stream.extract_sections
        end
      end

      def set(data)
        write do |stream|
          data = job.hide_secrets(data)
          stream.set(data)
        end
      end

      def append(data, offset)
        write do |stream|
          current_length = stream.size
          return -current_length unless current_length == offset

          data = job.hide_secrets(data)
          stream.append(data, offset)
          stream.size
        end
      end

      def exist?
        raise NotImplementedError
      end

      # def exist?
      #   trace_artifact&.exists? || current_path.present? || old_trace.present?
      # end

      # def read
      #   stream = Gitlab::Ci::Trace::Stream.new do
      #     if trace_artifact
      #       trace_artifact.open
      #     elsif current_path
      #       File.open(current_path, "rb")
      #     elsif old_trace
      #       StringIO.new(old_trace)
      #     end
      #   end

      #   yield stream
      # ensure
      #   stream&.close
      # end

      def read
        stream = Gitlab::Ci::Trace::Stream.new(io_read)

        yield stream
      ensure
        stream&.close
      end

      def write
        stream = Gitlab::Ci::Trace::Stream.new(io_write)

        yield(stream).tap do
          job.touch if job.needs_touch?
        end
      ensure
        stream&.close
      end

      # def erase!
      #   paths.each do |trace_path|
      #     FileUtils.rm(trace_path, force: true)
      #   end

      #   job.erase_old_trace!
      # end

      private

      def ensure_path
        raise NotImplementedError
      end

      def ensure_directory
        raise NotImplementedError
      end

      def paths
        raise NotImplementedError
      end

      def current_path
        raise NotImplementedError
      end

      def default_directory
        raise NotImplementedError
      end

      def default_path
        raise NotImplementedError
      end

      def deprecated_path
        raise NotImplementedError
      end

      def io_read
        raise NotImplementedError
      end

      def io_write
        raise NotImplementedError
      end
    end
  end
end
