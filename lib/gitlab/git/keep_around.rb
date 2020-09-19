# frozen_string_literal: true

# Makes sure a commit is kept around when Git garbage collection runs.
# Git GC will delete commits from the repository that are no longer in any
# branches or tags, but we want to keep some of these commits around, for
# example if they have comments or CI builds.
#
# For Geo's sake, pass in multiple shas rather than calling it multiple times,
# to avoid unnecessary syncing.
module Gitlab
  module Git
    class KeepAround
      def self.execute(repository, shas)
        new(repository).execute(shas)
      end

      def initialize(repository)
        @repository = repository
      end

      def execute(shas)
        shas.each do |sha|
          next unless sha.present? && commit_by(oid: sha)

          next if kept_around?(sha)

          # This will still fail if the file is corrupted (e.g. 0 bytes)
          raw_repository.write_ref(keep_around_ref_name(sha), sha)
        rescue Gitlab::Git::CommandError => ex
          Gitlab::AppLogger.error "Unable to create keep-around reference for repository #{disk_path}: #{ex}"
        end
      end

      def kept_around?(sha)
        ref_exists?(keep_around_ref_name(sha))
      end

      delegate :commit_by, :raw_repository, :ref_exists?, :disk_path, to: :@repository
      private :commit_by, :raw_repository, :ref_exists?, :disk_path

      private

      def keep_around_ref_name(sha)
        "refs/#{::Repository::REF_KEEP_AROUND}/#{sha}"
      end
    end
  end
end
