# Gitlab::Git::Commit is a wrapper around Gitaly::GitCommit
module Gitlab
  module Git
    class Commit
      include Gitlab::EncodingHelper

      attr_accessor :raw_commit, :head

      MAX_COMMIT_MESSAGE_DISPLAY_SIZE = 10.megabytes
      MIN_SHA_LENGTH = 7
      SERIALIZE_KEYS = [
        :id, :message, :parent_ids,
        :authored_date, :author_name, :author_email,
        :committed_date, :committer_name, :committer_email
      ].freeze

      attr_accessor *SERIALIZE_KEYS # rubocop:disable Lint/AmbiguousOperator

      def ==(other)
        return false unless other.is_a?(Gitlab::Git::Commit)

        id && id == other.id
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

          repo.log(options)
        end

        # Get single commit
        #
        # Ex.
        #   Commit.find(repo, '29eda46b')
        #
        #   Commit.find(repo, 'master')
        #
        # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/321
        def find(repo, commit_id = "HEAD")
          # Already a commit?
          return commit_id if commit_id.is_a?(Gitlab::Git::Commit)

          # A rugged reference?
          commit_id = Gitlab::Git::Ref.dereference_object(commit_id)

          # Some weird thing?
          return nil unless commit_id.is_a?(String)

          # This saves us an RPC round trip.
          return nil if commit_id.include?(':')

          commit = repo.wrapped_gitaly_errors do
            repo.gitaly_commit_client.find_commit(commit_id)
          end

          decorate(repo, commit) if commit
        rescue Gitlab::Git::CommandError, Gitlab::Git::Repository::NoRepository, ArgumentError
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
          repo.wrapped_gitaly_errors do
            repo.gitaly_commit_client.between(base, head)
          end
        end

        # Returns commits collection
        #
        # Ex.
        #   Commit.find_all(
        #     repo,
        #     ref: 'master',
        #     max_count: 10,
        #     skip: 5,
        #     order: :date
        #   )
        #
        #   +options+ is a Hash of optional arguments to git
        #     :ref is the ref from which to begin (SHA1 or name)
        #     :max_count is the maximum number of commits to fetch
        #     :skip is the number of commits to skip
        #     :order is the commits order and allowed value is :none (default), :date,
        #        :topo, or any combination of them (in an array). Commit ordering types
        #        are documented here:
        #        http://www.rubydoc.info/github/libgit2/rugged/Rugged#SORT_NONE-constant)
        #
        # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/326
        def find_all(repo, options = {})
          repo.wrapped_gitaly_errors do
            Gitlab::GitalyClient::CommitService.new(repo).find_all_commits(options)
          end
        end

        def decorate(repository, commit, ref = nil)
          Gitlab::Git::Commit.new(repository, commit, ref)
        end

        def shas_with_signatures(repository, shas)
          Gitlab::GitalyClient::CommitService.new(repository).filter_shas_with_signatures(shas)
        end

        # Only to be used when the object ids will not necessarily have a
        # relation to each other. The last 10 commits for a branch for example,
        # should go through .where
        def batch_by_oid(repo, oids)
          repo.wrapped_gitaly_errors do
            repo.gitaly_commit_client.list_commits_by_oid(oids)
          end
        end

        def extract_signature(repository, commit_id)
          repository.gitaly_commit_client.extract_signature(commit_id)
        end

        def extract_signature_lazily(repository, commit_id)
          BatchLoader.for({ repository: repository, commit_id: commit_id }).batch do |items, loader|
            items_by_repo = items.group_by { |i| i[:repository] }

            items_by_repo.each do |repo, items|
              commit_ids = items.map { |i| i[:commit_id] }

              signatures = batch_signature_extraction(repository, commit_ids)

              signatures.each do |commit_sha, signature_data|
                loader.call({ repository: repository, commit_id: commit_sha }, signature_data)
              end
            end
          end
        end

        def batch_signature_extraction(repository, commit_ids)
          repository.gitaly_commit_client.get_commit_signatures(commit_ids)
        end

        def get_message(repository, commit_id)
          BatchLoader.for({ repository: repository, commit_id: commit_id }).batch do |items, loader|
            items_by_repo = items.group_by { |i| i[:repository] }

            items_by_repo.each do |repo, items|
              commit_ids = items.map { |i| i[:commit_id] }

              messages = get_messages(repository, commit_ids)

              messages.each do |commit_sha, message|
                loader.call({ repository: repository, commit_id: commit_sha }, message)
              end
            end
          end
        end

        def get_messages(repository, commit_ids)
          repository.gitaly_commit_client.get_commit_messages(commit_ids)
        end
      end

      def initialize(repository, raw_commit, head = nil)
        raise "Nil as raw commit passed" unless raw_commit

        @repository = repository
        @head = head

        case raw_commit
        when Hash
          init_from_hash(raw_commit)
        when Gitaly::GitCommit
          init_from_gitaly(raw_commit)
        else
          raise "Invalid raw commit type: #{raw_commit.class}"
        end
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

      # Returns a diff object for the changes from this commit's first parent.
      # If there is no parent, then the diff is between this commit and an
      # empty repo. See Repository#diff for keys allowed in the +options+
      # hash.
      def diff_from_parent(options = {})
        @repository.gitaly_commit_client.diff_from_parent(self, options)
      end

      def deltas
        @deltas ||= begin
          deltas = @repository.gitaly_commit_client.commit_deltas(self)
          deltas.map { |delta| Gitlab::Git::Diff.new(delta) }
        end
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
          hash[key] = send(key) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def date
        committed_date
      end

      def diffs(options = {})
        Gitlab::Git::DiffCollection.new(diff_from_parent(options), options)
      end

      def parents
        parent_ids.map { |oid| self.class.find(@repository, oid) }.compact
      end

      def stats
        Gitlab::Git::CommitStats.new(@repository, self)
      end

      # Get ref names collection
      #
      # Ex.
      #   commit.ref_names(repo)
      #
      def ref_names(repo)
        refs(repo).map do |ref|
          ref.sub(%r{^refs/(heads|remotes|tags)/}, "")
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

      def merge_commit?
        parent_ids.size > 1
      end

      def tree_entry(path)
        return unless path.present?

        # We're only interested in metadata, so limit actual data to 1 byte
        # since Gitaly doesn't support "send no data" option.
        entry = @repository.gitaly_commit_client.tree_entry(id, path, 1)
        return unless entry

        # To be compatible with the rugged format
        entry = entry.to_h
        entry.delete(:data)
        entry[:name] = File.basename(path)
        entry[:type] = entry[:type].downcase

        entry
      end

      def to_gitaly_commit
        return raw_commit if raw_commit.is_a?(Gitaly::GitCommit)

        message_split = raw_commit.message.split("\n", 2)
        Gitaly::GitCommit.new(
          id: raw_commit.oid,
          subject: message_split[0] ? message_split[0].chomp.b : "",
          body: raw_commit.message.b,
          parent_ids: raw_commit.parent_ids,
          author: gitaly_commit_author_from_rugged(raw_commit.author),
          committer: gitaly_commit_author_from_rugged(raw_commit.committer)
        )
      end

      private

      def init_from_hash(hash)
        raw_commit = hash.symbolize_keys

        serialize_keys.each do |key|
          send("#{key}=", raw_commit[key]) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def init_from_gitaly(commit)
        @raw_commit = commit
        @id = commit.id
        # TODO: Once gitaly "takes over" Rugged consider separating the
        # subject from the message to make it clearer when there's one
        # available but not the other.
        @message = message_from_gitaly_body
        @authored_date = Time.at(commit.author.date.seconds).utc
        @author_name = commit.author.name.dup
        @author_email = commit.author.email.dup
        @committed_date = Time.at(commit.committer.date.seconds).utc
        @committer_name = commit.committer.name.dup
        @committer_email = commit.committer.email.dup
        @parent_ids = Array(commit.parent_ids)
      end

      def serialize_keys
        SERIALIZE_KEYS
      end

      def gitaly_commit_author_from_rugged(author_or_committer)
        Gitaly::CommitAuthor.new(
          name: author_or_committer[:name].b,
          email: author_or_committer[:email].b,
          date: Google::Protobuf::Timestamp.new(seconds: author_or_committer[:time].to_i)
        )
      end

      # Get a collection of Gitlab::Git::Ref objects for this commit.
      #
      # Ex.
      #   commit.ref(repo)
      #
      def refs(repo)
        repo.refs_hash[id]
      end

      def message_from_gitaly_body
        return @raw_commit.subject.dup if @raw_commit.body_size.zero?
        return @raw_commit.body.dup if full_body_fetched_from_gitaly?

        if @raw_commit.body_size > MAX_COMMIT_MESSAGE_DISPLAY_SIZE
          "#{@raw_commit.subject}\n\n--commit message is too big".strip
        else
          fetch_body_from_gitaly
        end
      end

      def full_body_fetched_from_gitaly?
        @raw_commit.body.bytesize == @raw_commit.body_size
      end

      def fetch_body_from_gitaly
        self.class.get_message(@repository, id)
      end
    end
  end
end
