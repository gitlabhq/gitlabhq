# frozen_string_literal: true

module Gitlab
  module FogbugzImport
    class Repository
      attr_accessor :raw_data

      def initialize(raw_data)
        @raw_data = raw_data
      end

      def valid?
        raw_data.is_a?(Hash)
      end

      def id
        raw_data['ixProject']
      end

      def name
        raw_data['sProject']
      end

      def safe_name
        name.gsub(/[^\s\w.-]/, '')
      end

      def path
        safe_name.gsub(/\s/, '_')
      end
    end
  end
end
