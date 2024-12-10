# frozen_string_literal: true

module Gitlab
  module Utils
    class TraversalIdCompactor
      CompactionLimitCannotBeAchievedError = Class.new(StandardError)
      RedundantCompactionEntry = Class.new(StandardError)
      UnexpectedCompactionEntry = Class.new(StandardError)

      class << self
        # This class compacts an array of traversal_ids by finding the most common namespace
        # and consolidating all children into an entry for that namespace. It continues this process
        # until the size of the final array is less than the limit. If it cannot achieve the limit
        # it raises a CompactionLimitCannotBeAchievedError.
        #
        # The traversal_ids input will look like the array below where each element in the sub-arrays
        # is a namespace id.
        #
        # [
        #   [1, 21],
        #   [1, 2, 3],
        #   [1, 2, 4],
        #   [1, 2, 5],
        #   [1, 2, 12, 13],
        #   [1, 6, 7],
        #   [1, 6, 8],
        #   [9, 10, 11]
        # ]
        #
        # The limit input is the maximum number of elements in the final array.

        # The compact method calls the compact_once method until the size of the final array is less
        # than the limit. It then returns the compacted list of traversal_ids
        # If it cannot achieve the limit it raises a CompactionLimitCannotBeAchievedError.

        def compact(traversal_ids, limit)
          traversal_ids = compact_once(traversal_ids) while traversal_ids.size > limit

          traversal_ids
        end

        # The compact_once method finds the most common namespace and compacts all children into an
        # entry for that namespace. It then returns the compacted list of traversal_ids.

        def compact_once(traversal_ids)
          most_common_namespace_path = find_most_common_namespace_path(traversal_ids)

          compacted_traversal_ids = traversal_ids.map do |traversal_id|
            if starts_with?(traversal_id, most_common_namespace_path)
              most_common_namespace_path
            else
              traversal_id
            end
          end

          compacted_traversal_ids.uniq
        end

        # The validate method performs two checks on the compacted_traversal_ids
        #  1. If there are redundant traversal_ids, for example [1,2,3,4] and [1,2,3]
        #  2. If there are unexpected entries, meaning a traversal_id not present in the origin_project_traversal_ids
        # If either case is found, it will raise an error
        # Otherwise, it will return true

        def validate!(origin_project_traversal_ids, compacted_traversal_ids)
          compacted_traversal_ids.each do |compacted_path|
            # Fail if there are unexpected entries
            raise UnexpectedCompactionEntry unless origin_project_traversal_ids.find do |original_path|
              starts_with?(original_path, compacted_path)
            end

            # Fail if there are redundant entries
            compacted_traversal_ids.each do |inner_compacted_path|
              next if inner_compacted_path == compacted_path

              raise RedundantCompactionEntry if starts_with?(inner_compacted_path, compacted_path)
            end
          end

          true
        end

        private

        # find_most_common_namespace_path method takes an array of traversal_ids and returns the most common namespace
        # For example, given the following traversal_ids it would return [1, 2]
        #
        # [
        #   [1, 21],
        #   [1, 2, 3],
        #   [1, 2, 4],
        #   [1, 2, 5],
        #   [1, 2, 12, 13],
        #   [1, 6, 7],
        #   [1, 6, 8],
        #   [9, 10, 11]
        # ]

        def find_most_common_namespace_path(traversal_ids)
          # namespace_counts is a tally of the number of times each namespace path occurs in the traversal_ids array
          # after removing any namespace paths that occur only once
          # The namespace path is the traversal_id without the last element
          namespace_counts = traversal_ids.each_with_object([]) do |traversal_id, result|
            result << traversal_id[0...-1] if traversal_id.size > 1
          end.tally

          # namespace is the namespace path that occurs the most times in the traversal_ids array after removing
          # any namespace paths that occur only once since compaction isn't necessary for those
          namespace = namespace_counts.reject { |_k, v| v == 1 }.sort_by { |k, v| [k.size, v] }.reverse.to_h.first

          # if namespace is nil it means there are no more namespaces to compact so
          # we raise a CompactionLimitCannotBeAchievedError
          raise CompactionLimitCannotBeAchievedError if namespace.nil?

          # return the most common namespace path
          namespace.first
        end

        # The starts_with? method returns true if the first n elements of the traversal_id match the namespace_path
        # For example:
        #
        # starts_with?([1, 2, 3], [1, 2]) #=> true
        # starts_with?([1, 2], [1, 2, 3]) #=> false
        # starts_with?([1, 2, 3], [1, 2, 3]) #=> true
        # starts_with?([1, 2, 3], [1, 2, 3, 4]) #=> false

        def starts_with?(traversal_id, namespace_path)
          traversal_id.first(namespace_path.length) == namespace_path
        end
      end
    end
  end
end
