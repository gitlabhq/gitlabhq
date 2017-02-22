# Gitlab::Git::Commit is a wrapper around native Rugged::Commit object
module Gitlab
  module Git
    class Commit
      include Gitlab::Git::EncodingHelper

      attr_accessor :raw_commit, :head, :refs

      SERIALIZE_KEYS = [
        :id, :message, :parent_ids,
        :authored_date, :author_name, :author_email,
        :committed_date, :committer_name, :committer_email
      ].freeze

      attr_accessor *SERIALIZE_KEYS # rubocop:disable Lint/AmbiguousOperator

      delegate :tree, to: :raw_commit

      def ==(other)
        return false unless other.is_a?(Gitlab::Git::Commit)

        methods = [:message, :parent_ids, :authored_date, :author_name,
                   :author_email, :committed_date, :committer_name,
                   :committer_email]

        methods.all? do |method|
          send(method) == other.send(method)
        end
      end

      class << self
        # Get commits collection
        #
        # Ex.
        #   Commit.where(
        #     repo: repo,
        #     ref: 'master',
        #     path: 'app/models',
        #     limit: 10,
        #     offset: 5,
        #   )
        #
        def where(options)
          repo = options.delete(:repo)
          raise 'Gitlab::Git::Repository is required' unless repo.respond_to?(:log)

          repo.log(options).map { |c| decorate(c) }
        end

        # Get single commit
        #
        # Ex.
        #   Commit.find(repo, '29eda46b')
        #
        #   Commit.find(repo, 'master')
        #
        def find(repo, commit_id = "HEAD")
          return decorate(commit_id) if commit_id.is_a?(Rugged::Commit)

          obj = if commit_id.is_a?(String)
                  repo.rev_parse_target(commit_id)
                else
                  Gitlab::Git::Ref.dereference_object(commit_id)
                end

          return nil unless obj.is_a?(Rugged::Commit)

          decorate(obj)
        rescue Rugged::ReferenceError, Rugged::InvalidError, Rugged::ObjectError, Gitlab::Git::Repository::NoRepository
          nil
        end

        # Get last commit for HEAD
        #
        # Ex.
        #   Commit.last(repo)
        #
        def last(repo)
          find(repo)
        end

        # Get last commit for specified path and ref
        #
        # Ex.
        #   Commit.last_for_path(repo, '29eda46b', 'app/models')
        #
        #   Commit.last_for_path(repo, 'master', 'Gemfile')
        #
        def last_for_path(repo, ref, path = nil)
          where(
            repo: repo,
            ref: ref,
            path: path,
            limit: 1
          ).first
        end

        # Get commits between two revspecs
        # See also #repository.commits_between
        #
        # Ex.
        #   Commit.between(repo, '29eda46b', 'master')
        #
        def between(repo, base, head)
          repo.commits_between(base, head).map do |commit|
            decorate(commit)
          end
        rescue Rugged::ReferenceError
          []
        end

        # Delegate Repository#find_commits
        def find_all(repo, options = {})
          repo.find_commits(options)
        end

        def decorate(commit, ref = nil)
          Gitlab::Git::Commit.new(commit, ref)
        end

        # Returns a diff object for the changes introduced by +rugged_commit+.
        # If +rugged_commit+ doesn't have a parent, then the diff is between
        # this commit and an empty repo.  See Repository#diff for the keys
        # allowed in the +options+ hash.
        def diff_from_parent(rugged_commit, options = {})
          options ||= {}
          break_rewrites = options[:break_rewrites]
          actual_options = Gitlab::Git::Diff.filter_diff_options(options)

          diff = if rugged_commit.parents.empty?
                   rugged_commit.diff(actual_options.merge(reverse: true))
                 else
                   rugged_commit.parents[0].diff(rugged_commit, actual_options)
                 end

          diff.find_similar!(break_rewrites: break_rewrites)
          diff
        end
      end

      def initialize(raw_commit, head = nil)
        raise "Nil as raw commit passed" unless raw_commit

        if raw_commit.is_a?(Hash)
          init_from_hash(raw_commit)
        elsif raw_commit.is_a?(Rugged::Commit)
          init_from_rugged(raw_commit)
        else
          raise "Invalid raw commit type: #{raw_commit.class}"
        end

        @head = head
      end

      def sha
        id
      end

      def short_id(length = 10)
        id.to_s[0..length]
      end

      def safe_message
        @safe_message ||= message
      end

      def created_at
        committed_date
      end

      # Was this commit committed by a different person than the original author?
      def different_committer?
        author_name != committer_name || author_email != committer_email
      end

      def parent_id
        parent_ids.first
      end

      # Shows the diff between the commit's parent and the commit.
      #
      # Cuts out the header and stats from #to_patch and returns only the diff.
      def to_diff(options = {})
        diff_from_parent(options).patch
      end

      # Returns a diff object for the changes from this commit's first parent.
      # If there is no parent, then the diff is between this commit and an
      # empty repo.  See Repository#diff for keys allowed in the +options+
      # hash.
      def diff_from_parent(options = {})
        Commit.diff_from_parent(raw_commit, options)
      end

      def has_zero_stats?
        stats.total.zero?
      rescue
        true
      end

      def no_commit_message
        "--no commit message"
      end

      def to_hash
        serialize_keys.map.with_object({}) do |key, hash|
          hash[key] = send(key)
        end
      end

      def date
        committed_date
      end

      def diffs(options = {})
        Gitlab::Git::DiffCollection.new(diff_from_parent(options), options)
      end

      def parents
        raw_commit.parents.map { |c| Gitlab::Git::Commit.new(c) }
      end

      def stats
        Gitlab::Git::CommitStats.new(self)
      end

      def to_patch(options = {})
        begin
          raw_commit.to_mbox(options)
        rescue Rugged::InvalidError => ex
          if ex.message =~ /Commit \w+ is a merge commit/
            'Patch format is not currently supported for merge commits.'
          end
        end
      end

      # Get a collection of Rugged::Reference objects for this commit.
      #
      # Ex.
      #   commit.ref(repo)
      #
      def refs(repo)
        repo.refs_hash[id]
      end

      # Get ref names collection
      #
      # Ex.
      #   commit.ref_names(repo)
      #
      def ref_names(repo)
        refs(repo).map do |ref|
          ref.name.sub(%r{^refs/(heads|remotes|tags)/}, "")
        end
      end

      def message
        encode! @message
      end

      def author_name
        encode! @author_name
      end

      def author_email
        encode! @author_email
      end

      def committer_name
        encode! @committer_name
      end

      def committer_email
        encode! @committer_email
      end

      private

      def init_from_hash(hash)
        raw_commit = hash.symbolize_keys

        serialize_keys.each do |key|
          send("#{key}=", raw_commit[key])
        end
      end

      def init_from_rugged(commit)
        author = commit.author
        committer = commit.committer

        @raw_commit = commit
        @id = commit.oid
        @message = commit.message
        @authored_date = author[:time]
        @committed_date = committer[:time]
        @author_name = author[:name]
        @author_email = author[:email]
        @committer_name = committer[:name]
        @committer_email = committer[:email]
        @parent_ids = commit.parents.map(&:oid)
      end

      def serialize_keys
        SERIALIZE_KEYS
      end
    end
  end
end
