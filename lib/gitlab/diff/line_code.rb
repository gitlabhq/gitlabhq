module Gitlab
  module Diff
    class LineCode
      def self.generate(file_path, key_attributes)
        "#{Digest::SHA1.hexdigest(file_path)}_#{key_attributes[0]}_#{key_attributes[1]}"
      end
    end
  end
end
