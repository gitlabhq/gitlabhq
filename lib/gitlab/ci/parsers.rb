module Gitlab
  module Ci
    module Parsers
      def self.fabricate!(file_type)
        "Gitlab::Ci::Parsers::#{file_type.classify}".constantize.new
      end
    end
  end
end
