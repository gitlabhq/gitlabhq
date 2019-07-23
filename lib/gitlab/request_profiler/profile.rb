# frozen_string_literal: true

module Gitlab
  module RequestProfiler
    class Profile
      attr_reader :name, :time, :file_path, :request_path, :profile_mode, :type

      alias_method :to_param, :name

      def initialize(name)
        @name = name
        @file_path = File.join(PROFILES_DIR, name)

        set_attributes
      end

      def valid?
        @request_path.present?
      end

      def content_type
        case type
        when 'html'
          'text/html'
        when 'txt'
          'text/plain'
        end
      end

      private

      def set_attributes
        matches = name.match(/^(?<path>.*)_(?<timestamp>\d+)(_(?<profile_mode>\w+))?\.(?<type>html|txt)$/)
        return unless matches

        @request_path      = matches[:path].tr('|', '/')
        @time              = Time.at(matches[:timestamp].to_i).utc
        @profile_mode      = matches[:profile_mode] || 'unknown'
        @type              = matches[:type]
      end
    end
  end
end
