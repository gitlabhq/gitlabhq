module Gitlab
  module GitoriousImport
    class Client
      attr_reader :repo_list

      def initialize(repo_list)
        @repo_list = repo_list
      end

      def authorize_url(redirect_uri)
        "#{GITORIOUS_HOST}/gitlab-import?callback_url=#{redirect_uri}"
      end

      def repos
        @repos ||= repo_names.map { |full_name| GitoriousImport::Repository.new(full_name) }
      end

      def repo(id)
        repos.find { |repo| repo.id == id }
      end

      private

      def repo_names
        repo_list.to_s.split(',').map(&:strip).reject(&:blank?)
      end
    end
  end
end
