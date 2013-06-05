require 'gitlab/git_stats_log_parser'

module Gitlab
  class GitStats
    attr_accessor :repo, :ref

    def initialize repo, ref
      @repo, @ref = repo, ref
    end

    def log
      args = ['--format=%aN%x0a%ad', '--date=short', '--shortstat', '--no-merges']
      repo.git.run(nil, 'log', nil, {}, args)
    end

    def parsed_log
      LogParser.parse_log(log)
    end
  end
end
