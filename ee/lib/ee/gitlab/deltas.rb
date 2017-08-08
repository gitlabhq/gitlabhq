module EE
  module Gitlab
    module Deltas
      def self.delta_size_check(change, repo)
        size_of_deltas = 0

        begin
          tree_a = repo.lookup(change[:oldrev])
          tree_b = repo.lookup(change[:newrev])
          diff = tree_a.diff(tree_b)

          diff.each_delta do |d|
            new_file_size = d.deleted? ? 0 : ::Gitlab::Git::Blob.raw(repo, d.new_file[:oid]).size

            size_of_deltas += new_file_size
          end

          size_of_deltas
        rescue Rugged::OdbError, Rugged::ReferenceError, Rugged::InvalidError
          size_of_deltas
        end
      end
    end
  end
end
