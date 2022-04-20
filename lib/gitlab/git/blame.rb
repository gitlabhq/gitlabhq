# frozen_string_literal: true

module Gitlab
  module Git
    class Blame
      include Gitlab::EncodingHelper

      attr_reader :lines, :blames, :range

      def initialize(repository, sha, path, range: nil)
        @repo = repository
        @sha = sha
        @path = path
        @range = range
        @lines = []
        @blames = load_blame
      end

      def each
        @blames.each do |blame|
          yield(blame.commit, blame.line, blame.previous_path)
        end
      end

      private

      def range_spec
        "#{range.first},#{range.last}" if range
      end

      def load_blame
        output = encode_utf8(
          @repo.gitaly_commit_client.raw_blame(@sha, @path, range: range_spec)
        )

        process_raw_blame(output)
      end

      def process_raw_blame(output)
        start_line = nil
        lines = []
        final = []
        info = {}
        commits = {}
        commit_id = nil
        previous_paths = {}

        # process the output
        output.split("\n").each do |line|
          if line[0, 1] == "\t"
            lines << line[1, line.size]
          elsif m = /^(\w{40}) (\d+) (\d+)/.match(line)
            # Removed these instantiations for performance but keeping them for reference:
            # commit_id, old_lineno, lineno = m[1], m[2].to_i, m[3].to_i
            commit_id = m[1]
            commits[commit_id] = nil unless commits.key?(commit_id)
            info[m[3].to_i] = [commit_id, m[2].to_i]

            # Assumption: the first line returned by git blame is lowest-numbered
            # This is true unless we start passing it `--incremental`.
            start_line = m[3].to_i if start_line.nil?
          elsif line.start_with?("previous ")
            # previous 1485b69e7b839a21436e81be6d3aa70def5ed341 initial-commit
            # previous 9521e52704ee6100e7d2a76896a4ef0eb53ff1b8 "\303\2511\\\303\251\\303\\251\n"
            #                                                   ^ char index 50
            previous_paths[commit_id] = unquote_path(line[50..])
          end
        end

        Gitlab::Git::Commit.batch_by_oid(@repo, commits.keys).each do |commit|
          commits[commit.sha] = commit
        end

        # get it together
        info.sort.each do |lineno, (commit_id, old_lineno)|
          final << BlameLine.new(
            lineno,
            old_lineno,
            commits[commit_id],
            lines[lineno - start_line],
            previous_paths[commit_id]
          )
        end

        @lines = final
      end
    end

    class BlameLine
      attr_accessor :lineno, :oldlineno, :commit, :line, :previous_path

      def initialize(lineno, oldlineno, commit, line, previous_path)
        @lineno = lineno
        @oldlineno = oldlineno
        @commit = commit
        @line = line
        @previous_path = previous_path
      end
    end
  end
end
