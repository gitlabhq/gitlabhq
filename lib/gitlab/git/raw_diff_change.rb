# frozen_string_literal: true

module Gitlab
  module Git
    # This class behaves like a struct with fields :blob_id, :blob_size, :operation, :old_path, :new_path
    # All those fields are (binary) strings or integers
    class RawDiffChange
      attr_reader :blob_id, :blob_size, :old_path, :new_path, :operation

      def initialize(raw_change)
        if raw_change.is_a?(Gitaly::GetRawChangesResponse::RawChange)
          @blob_id = raw_change.blob_id
          @blob_size = raw_change.size
          @old_path = raw_change.old_path_bytes.presence
          @new_path = raw_change.new_path_bytes.presence
          @operation = raw_change.operation&.downcase || :unknown
        else
          parse(raw_change)
        end
      end

      private

      # Input data has the following format:
      #
      # When a file has been modified:
      # 7e3e39ebb9b2bf433b4ad17313770fbe4051649c 669 M\tfiles/ruby/popen.rb
      #
      # When a file has been renamed:
      # 85bc2f9753afd5f4fc5d7c75f74f8d526f26b4f3 107 R060\tfiles/js/commit.js.coffee\tfiles/js/commit.coffee
      def parse(raw_change)
        @blob_id, @blob_size, @raw_operation, raw_paths = raw_change.split(' ', 4)
        @blob_size = @blob_size.to_i
        @operation = extract_operation
        @old_path, @new_path = extract_paths(raw_paths)
      end

      def extract_paths(file_path)
        case operation
        when :copied, :renamed
          file_path.split("\t")
        when :deleted
          [file_path, nil]
        when :added
          [nil, file_path]
        else
          [file_path, file_path]
        end
      end

      def extract_operation
        return :unknown unless @raw_operation

        case @raw_operation[0]
        when 'A'
          :added
        when 'C'
          :copied
        when 'D'
          :deleted
        when 'M'
          :modified
        when 'R'
          :renamed
        when 'T'
          :type_changed
        else
          :unknown
        end
      end
    end
  end
end
