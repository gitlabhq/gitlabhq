module Gitlab
  module RequestProfiler
    class Profile
      attr_reader :name, :time, :request_path

      alias_method :to_param, :name

      def self.all
        Dir["#{PROFILES_DIR}/*.html"].map do |path|
          new(File.basename(path))
        end
      end

      def self.find(name)
        name_dup = name.dup
        name_dup << '.html' unless name.end_with?('.html')

        file_path = "#{PROFILES_DIR}/#{name_dup}"
        return unless File.exist?(file_path)

        new(name_dup)
      end

      def initialize(name)
        @name = name

        set_attributes
      end

      def content
        File.read("#{PROFILES_DIR}/#{name}")
      end

      private

      def set_attributes
        _, path, timestamp = name.split(/(.*)_(\d+)\.html$/)
        @request_path      = path.tr('|', '/')
        @time              = Time.at(timestamp.to_i).utc
      end
    end
  end
end
