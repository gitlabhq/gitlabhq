# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'kubernetes'
      end
    end
  end
end
