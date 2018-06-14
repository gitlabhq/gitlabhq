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
          yield(blame.commit, blame.line)
        end
      end

      private

      def load_blame
        output = encode_utf8(@repo.gitaly_commit_client.raw_blame(@sha, @path))

        process_raw_blame(output)
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

        Gitlab::Git::Commit.batch_by_oid(@repo, commits.keys).each do |commit|
          commits[commit.sha] = commit
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
