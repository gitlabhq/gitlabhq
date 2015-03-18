module Gitlab
  module GitoriousImport
    GITORIOUS_HOST = "https://gitorious.org"

    class Client
      attr_reader :repo_list

      def initialize(repo_list)
        @repo_list = repo_list
      end

      def authorize_url(redirect_uri)
        "#{GITORIOUS_HOST}/gitlab-import?callback_url=#{redirect_uri}"
      end

      def repos
        @repos ||= repo_names.map { |full_name| Repository.new(full_name) }
      end

      def repo(id)
        repos.find { |repo| repo.id == id }
      end

      private

      def repo_names
        repo_list.to_s.split(',').map(&:strip).reject(&:blank?)
      end
    end

    Repository = Struct.new(:full_name) do
      def id
        Digest::SHA1.hexdigest(full_name)
      end

      def namespace
        segments.first
      end

      def path
        segments.last
      end

      def name
        path.titleize
      end

      def description
        ""
      end

      def import_url
        "#{GITORIOUS_HOST}/#{full_name}.git"
      end

      private

      def segments
        full_name.split('/')
      end
    end
  end
end
