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
            Gitlab::Git::Commit.new(@repo, blame.commit),
            blame.line
          )
        end
      end

      private

      def load_blame
        raw_output = @repo.gitaly_migrate(:blame) do |is_enabled|
          if is_enabled
            load_blame_by_gitaly
          else
            load_blame_by_shelling_out
          end
        end

        output = encode_utf8(raw_output)
        process_raw_blame output
      end

      def load_blame_by_gitaly
        @repo.gitaly_commit_client.raw_blame(@sha, @path)
      end

      def load_blame_by_shelling_out
        @repo.shell_blame(@sha, @path)
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
