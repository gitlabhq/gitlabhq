module Gitlab
  module Diff
    class LineCode
      def self.generate(file_path, new_line_position, old_line_position)
        "#{Digest::SHA1.hexdigest(file_path)}_#{old_line_position}_#{new_line_position}"
      end
    end
  end
end
