module Gitlab
  module GoogleCodeImport
    class Client
      attr_reader :raw_data

      def initialize(raw_data)
        @raw_data = raw_data
      end

      def valid?
        raw_data.is_a?(Hash) && raw_data["kind"] == "projecthosting#user" && raw_data.has_key?("projects")
      end

      def repos
        @repos ||= raw_data["projects"].map { |raw_repo| GoogleCodeImport::Repository.new(raw_repo) }.select(&:git?)
      end

      def repo(id)
        repos.find { |repo| repo.id == id }
      end
    end
  end
end
