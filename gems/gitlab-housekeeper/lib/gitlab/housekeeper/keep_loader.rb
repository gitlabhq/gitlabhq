# frozen_string_literal: true

require 'pathname'
require 'active_support/core_ext/string'
require 'gitlab/housekeeper/keep'

module Gitlab
  module Housekeeper
    class KeepLoader
      KEEPS_GLOB = "keeps/*.rb"

      def initialize(requested: nil)
        @requested = requested
      end

      def keeps
        Dir.glob(KEEPS_GLOB).each { |file| require(Pathname(file).expand_path.to_s) }
        return all_keeps if requested.nil?

        requested.map { |keep| keep.is_a?(String) ? keep.constantize : keep }
      end

      private

      attr_reader :requested

      def all_keeps
        ObjectSpace.each_object(Class).select { |klass| klass < Keep }
      end
    end
  end
end
