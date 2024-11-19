# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      module PaginatedDiffs
        include Gitlab::Utils::StrongMemoize
        extend ::Gitlab::Utils::Override

        override :diffs
        def diffs
          merge_request_diff.opening_external_diff do
            # Avoiding any extra queries.
            collection = paginated_collection.to_a

            # The offset collection and calculation is required so that we
            # know how much has been loaded in previous batches, collapsing
            # the current paginated set accordingly (collection limit calculation).
            # See: https://docs.gitlab.com/ee/development/diffs.html#diff-collection-limits
            #
            offset_index = collection.first&.index
            options = diff_options.dup

            collection =
              if offset_index && offset_index > 0
                offset_collection = relation.limit(offset_index)
                options[:offset_index] = offset_index
                offset_collection + collection
              else
                collection
              end

            Gitlab::Git::DiffCollection.new(collection.map(&:to_hash), options)
          end
        end
        strong_memoize_attr :diffs

        private

        attr_reader :merge_request_diff, :paginated_collection

        def relation
          merge_request_diff.merge_request_diff_files
        end
      end
    end
  end
end
