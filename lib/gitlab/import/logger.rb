module Gitlab
  module Import
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'importer'
      end
    end
  end
end
