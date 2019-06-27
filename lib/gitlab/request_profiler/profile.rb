# frozen_string_literal: true

module Gitlab
  module RequestProfiler
    class Profile
      attr_reader :name, :time, :file_path, :request_path, :profile_mode, :type

      alias_method :to_param, :name

      def self.all
        Dir["#{PROFILES_DIR}/*.{html,txt}"].map do |path|
          new(File.basename(path))
        end
      end

      def self.find(name)
        file_path = File.join(PROFILES_DIR, name)
        return unless File.exist?(file_path)

        new(name)
      end

      def initialize(name)
        @name = name
        @file_path = File.join(PROFILES_DIR, name)

        set_attributes
      end

      def content
        File.read("#{PROFILES_DIR}/#{name}")
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
        _, path, timestamp, profile_mode, type = name.split(/(.*)_(\d+)_(.*)\.(html|txt)$/)
        @request_path      = path.tr('|', '/')
        @time              = Time.at(timestamp.to_i).utc
        @profile_mode      = profile_mode
        @type              = type
      end
    end
  end
end
