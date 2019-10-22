# frozen_string_literal: true

module QA
  module Runtime
    class GPG
      attr_reader :key, :key_id

      def initialize
        @key_id = 'B8358D73048DACC4'
        import_key(File.expand_path('qa/ee/fixtures/gpg/admin.asc'))
        @key = collect_key.first
      end

      private

      def import_key(path)
        import_key = "gpg --import #{path}"
        execute(import_key)
      end

      def collect_key
        get_ascii_format = "gpg --armor --export #{@key_id}"
        execute(get_ascii_format)
      end

      def execute(command)
        Open3.capture2e(*command) do |stdin, out, wait|
          out.each_char { |char| print char }

          if wait.value.exited? && wait.value.exitstatus.nonzero?
            raise CommandError, "Command `#{command}` failed!"
          end
        end
      end
    end
  end
end
