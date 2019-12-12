# frozen_string_literal: true

module Gitlab
  module Elasticsearch
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'elasticsearch'
      end
    end
  end
end
