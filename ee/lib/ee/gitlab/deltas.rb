module EE
  module Gitlab
    module Deltas
      def self.delta_size_check(change, repo)
        size_of_deltas = 0

        begin
          tree_a = repo.lookup(change[:oldrev])
          tree_b = repo.lookup(change[:newrev])

          return size_of_deltas unless diffable?(tree_a) && diffable?(tree_b)

          diff = tree_a.diff(tree_b)

          diff.each_delta do |d|
            next if d.deleted?

            blob = ::Gitlab::Git::Blob.raw(repo, d.new_file[:oid])

            # It's possible the OID points to a commit or empty object
            next unless blob

            size_of_deltas += blob.size
          end

          size_of_deltas
        rescue Rugged::OdbError, Rugged::ReferenceError, Rugged::InvalidError
          size_of_deltas
        end
      end

      def self.diffable?(object)
        [Rugged::Commit, Rugged::Tree].include?(object.class)
      end
    end
  end
end
