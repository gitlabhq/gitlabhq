# Gitaly note: JV: needs 1 RPC for #load_blame.

module Gitlab
  module Git
    class Blame
      include Gitlab::EncodingHelper

      attr_reader :lines, :blames

      def initialize(repository, sha, path)
        @repo = repository
        @sha = sha
        @path = path
        @lines = []
        @blames = load_blame
      end

      def each
        @blames.each do |blame|
          yield(
            Gitlab::Git::Commit.new(blame.commit),
            blame.line
          )
        end
      end

      private

      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/376
      def load_blame
        cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{@repo.path} blame -p #{@sha} -- #{@path})
        # Read in binary mode to ensure ASCII-8BIT
        raw_output = IO.popen(cmd, 'rb') {|io| io.read }
        output = encode_utf8(raw_output)
        process_raw_blame output
      end

      def process_raw_blame(output)
        lines, final = [], []
        info, commits = {}, {}

        # process the output
        output.split("\n").each do |line|
          if line[0, 1] == "\t"
            lines << line[1, line.size]
          elsif m = /^(\w{40}) (\d+) (\d+)/.match(line)
            commit_id, old_lineno, lineno = m[1], m[2].to_i, m[3].to_i
            commits[commit_id] = nil unless commits.key?(commit_id)
            info[lineno] = [commit_id, old_lineno]
          end
        end

        # load all commits in single call
        commits.keys.each do |key|
          commits[key] = @repo.lookup(key)
        end

        # get it together
        info.sort.each do |lineno, (commit_id, old_lineno)|
          commit = commits[commit_id]
          final << BlameLine.new(lineno, old_lineno, commit, lines[lineno - 1])
        end

        @lines = final
      end
    end

    class BlameLine
      attr_accessor :lineno, :oldlineno, :commit, :line
      def initialize(lineno, oldlineno, commit, line)
        @lineno = lineno
        @oldlineno = oldlineno
        @commit = commit
        @line = line
      end
    end
  end
end
