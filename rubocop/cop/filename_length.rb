# frozen_string_literal: true

module RuboCop
  module Cop
    class FilenameLength < RuboCop::Cop::Base
      include RangeHelp

      FILEPATH_MAX_BYTES = 256
      FILENAME_MAX_BYTES = 100
      MSG_FILEPATH_LEN = "This file path is too long. It should be #{FILEPATH_MAX_BYTES} or less".freeze
      MSG_FILENAME_LEN = "This file name is too long. It should be #{FILENAME_MAX_BYTES} or less".freeze

      def on_new_investigation
        file_path = processed_source.file_path
        return if config.file_to_exclude?(file_path)

        if file_path.bytesize > FILEPATH_MAX_BYTES
          add_offense(source_range(processed_source.buffer, 1, 0), message: MSG_FILEPATH_LEN)
        elsif File.basename(file_path).bytesize > FILENAME_MAX_BYTES
          add_offense(source_range(processed_source.buffer, 1, 0), message: MSG_FILENAME_LEN)
        end
      end
    end
  end
end
