module Gitlab
  module Ci
    class Trace
      attr_reader :job

      delegate :old_trace, to: :job

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
        FileUtils.exists?(full_path)
      end

      def read
        stream = Gitlab::Ci::Trace::Stream.new do
          File.open(full_path, "rb")
        end

        yield stream
      ensure
        stream&.close
      end

      def write
        ensure_directory

        stream = Gitlab::Ci::Trace::Stream.new do
          File.open(full_path, "a+b")
        end

        yield(stream).tap do
          job.touch if job.needs_touch?
        end
      ensure
        stream&.close
      end

      def erase!
        FileUtils.rm(full_path, force: true)

        job.erase_old_trace!
      end

      def full_path
        File.join(directory, "#{job.id}.log")
      end

      def directory
        File.join(
          Settings.gitlab_ci.builds_path,
          job.created_at.utc.strftime("%Y_%m"),
          job.project_id.to_s
        )
      end

      private

      def ensure_directory
        unless Dir.exist?(default_directory)
          FileUtils.mkdir_p(default_directory)
        end
      end
    end
  end
end
