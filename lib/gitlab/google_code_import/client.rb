module Gitlab
  module GoogleCodeImport
    class Client
      attr_reader :raw_data

      def self.mask_email(author)
        parts = author.split("@", 2)
        parts[0] = "#{parts[0][0...-3]}..."
        parts.join("@")
      end

      def initialize(raw_data)
        @raw_data = raw_data
      end

      def valid?
        raw_data.is_a?(Hash) && raw_data["kind"] == "projecthosting#user" && raw_data.has_key?("projects")
      end

      def repos
        @repos ||= raw_data["projects"].map { |raw_repo| GoogleCodeImport::Repository.new(raw_repo) }.select(&:git?)
      end

      def incompatible_repos
        @incompatible_repos ||= raw_data["projects"].map { |raw_repo| GoogleCodeImport::Repository.new(raw_repo) }.reject(&:git?)
      end

      def repo(id)
        repos.find { |repo| repo.id == id }
      end

      def user_map
        user_map = Hash.new { |hash, user| hash[user] = self.class.mask_email(user) }

        repos.each do |repo|
          next unless repo.valid? && repo.issues

          repo.issues.each do |raw_issue|
            # Touching is enough to add the entry and masked email.
            user_map[raw_issue["author"]["name"]]

            raw_issue["comments"]["items"].each do |raw_comment|
              user_map[raw_comment["author"]["name"]]
            end
          end
        end

        Hash[user_map.sort]
      end
    end
  end
end
