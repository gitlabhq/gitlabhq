# frozen_string_literal: true

module Gitlab
  module Git
    class ChangedPath
      attr_reader :status, :path

      def initialize(status:, path:)
        @status = status
        @path = path
      end

      def new_file?
        status == :ADDED
      end
    end
  end
end
