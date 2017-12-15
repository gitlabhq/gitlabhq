module Gitlab
  module Geo
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'geo'
      end
    end
  end
end
