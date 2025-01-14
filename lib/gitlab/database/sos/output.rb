# frozen_string_literal: true

module Gitlab
  module Database
    module Sos
      class Output
        def self.writing(path, mode:)
          output = new(path, mode: mode)
          yield output
        ensure
          output.finish
        end

        def initialize(path, mode:)
          @mode = mode
          if mode == :zip
            @zip = Zip::File.open(path, create: true) # rubocop:disable Performance/Rubyzip -- opening a file so no performance issues
          elsif mode == :directory # Used in testing, it's a lot easier to inspect a directory than a zip file
            @dir = path
          else
            raise "mode must be one of :zip, :directory"
          end
        end

        def finish
          @zip.close if @mode == :zip
        end

        def write_file(relative_path)
          if @mode == :zip
            @zip.get_output_stream(relative_path) do |f|
              yield f
            end
          else
            abs_path = File.join(@dir, relative_path)
            FileUtils.mkdir_p(File.dirname(abs_path))
            File.open(abs_path, 'w+') do |f|
              yield f
            end
          end
        end
      end
    end
  end
end
