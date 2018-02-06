module Gitlab
  module GoogleCodeImport
    class Repository
      attr_accessor :raw_data

      def initialize(raw_data)
        @raw_data = raw_data
      end

      def valid?
        raw_data.is_a?(Hash) && raw_data["kind"] == "projecthosting#project"
      end

      def id
        raw_data["externalId"]
      end

      def name
        raw_data["name"]
      end

      def summary
        raw_data["summary"]
      end

      def description
        raw_data["description"]
      end

      def git?
        raw_data["versionControlSystem"] == "git"
      end

      def import_url
        raw_data["repositoryUrls"].first
      end

      def issues
        raw_data["issues"] && raw_data["issues"]["items"]
      end
    end
  end
end
