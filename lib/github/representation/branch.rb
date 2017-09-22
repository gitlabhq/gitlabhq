module Github
  module Representation
    class Branch < Representation::Base
      attr_reader :repository

      def user
        raw.dig('user', 'login') || 'unknown'
      end

      def repo
        return @repo if defined?(@repo)

        @repo = Github::Representation::Repo.new(raw['repo']) if raw['repo'].present?
      end

      def ref
        raw['ref']
      end

      def sha
        raw['sha']
      end

      def short_sha
        Commit.truncate_sha(sha)
      end

      def exists?
        return @exists if defined?(@exists)

        @exists = repository.branch_exists?(ref)
      end

      def valid?
        sha.present? && ref.present?
      end

      def restore!(name)
        repository.create_branch(name, sha)
      rescue Gitlab::Git::Repository::InvalidRef => e
        Rails.logger.error("#{self.class.name}: Could not restore branch #{name}: #{e}")
      end

      def remove!(name)
        repository.delete_branch(name)
      rescue Gitlab::Git::Repository::DeleteBranchError => e
        Rails.logger.error("#{self.class.name}: Could not remove branch #{name}: #{e}")
      end

      private

      def repository
        @repository ||= options.fetch(:repository)
      end
    end
  end
end
