module Gitlab
  module Plugin
    def self.files
      Dir.glob(Rails.root.join('plugins/*')).select do |entry|
        File.file?(entry)
      end
    end

    def self.execute_all_async(data)
      files.each do |file|
        PluginWorker.perform_async(file, data)
      end
    end

    def self.execute(file, data)
      # Prepare the hook subprocess. Attach a pipe to its stdin, and merge
      # both its stdout and stderr into our own stdout.
      stdin_reader, stdin_writer = IO.pipe
      hook_pid = spawn({}, file, in: stdin_reader, err: :out)
      stdin_reader.close

      # Submit changes to the hook via its stdin.
      begin
        IO.copy_stream(StringIO.new(data.to_json), stdin_writer)
      rescue Errno::EPIPE
        # It is not an error if the hook does not consume all of its input.
      end

      # Close the pipe to let the hook know there is no further input.
      stdin_writer.close

      Process.wait(hook_pid)
      $?.success?
    end
  end
end
