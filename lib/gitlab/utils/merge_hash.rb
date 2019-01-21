# frozen_string_literal: true

require_dependency 'gitlab/utils'

module Gitlab
  module Utils
    module MergeHash
      extend self
      # Deep merges an array of hashes
      #
      # [{ hello: ["world"] },
      #  { hello: "Everyone" },
      #  { hello: { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzien dobry'] } },
      #   "Goodbye", "Hallo"]
      # =>  [
      #       {
      #         hello:
      #           [
      #             "world",
      #             "Everyone",
      #             { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzien dobry'] }
      #           ]
      #       },
      #       "Goodbye"
      #     ]
      def merge(elements)
        merged, *other_elements = elements

        other_elements.each do |element|
          merged = merge_hash_tree(merged, element)
        end

        merged
      end

      # This extracts all keys and values from a hash into an array
      #
      # { hello: "world", this: { crushes: ["an entire", "hash"] } }
      # => [:hello, "world", :this, :crushes, "an entire", "hash"]
      def crush(array_or_hash)
        if array_or_hash.is_a?(Array)
          crush_array(array_or_hash)
        else
          crush_hash(array_or_hash)
        end
      end

      private

      def merge_hash_into_array(array, new_hash)
        crushed_new_hash = crush_hash(new_hash)
        # Merge the hash into an existing element of the array if there is overlap
        if mergeable_index = array.index { |element| crushable?(element) && (crush(element) & crushed_new_hash).any? }
          array[mergeable_index] = merge_hash_tree(array[mergeable_index], new_hash)
        else
          array << new_hash
        end

        array
      end

      def merge_hash_tree(first_element, second_element)
        # If one of the elements is an object, and the other is a Hash or Array
        # we can check if the object is already included. If so, we don't need to do anything
        #
        # Handled cases
        # [Hash, Object], [Array, Object]
        if crushable?(first_element) && crush(first_element).include?(second_element)
          first_element
        elsif crushable?(second_element) && crush(second_element).include?(first_element)
          second_element
        # When the first is an array, we need to go over every element to see if
        # we can merge deeper. If no match is found, we add the element to the array
        #
        # Handled cases:
        # [Array, Hash]
        elsif first_element.is_a?(Array) && second_element.is_a?(Hash)
          merge_hash_into_array(first_element, second_element)
        elsif first_element.is_a?(Hash) && second_element.is_a?(Array)
          merge_hash_into_array(second_element, first_element)
        # If both of them are hashes, we can deep_merge with the same logic
        #
        # Handled cases:
        # [Hash, Hash]
        elsif first_element.is_a?(Hash) && second_element.is_a?(Hash)
          first_element.deep_merge(second_element) { |key, first, second| merge_hash_tree(first, second) }
        # If both elements are arrays, we try to merge each element separatly
        #
        # Handled cases
        # [Array, Array]
        elsif first_element.is_a?(Array) && second_element.is_a?(Array)
          first_element.map { |child_element| merge_hash_tree(child_element, second_element) }
        # If one or both elements are a GroupDescendant, we wrap create an array
        # combining them.
        #
        # Handled cases:
        # [Object, Object], [Array, Array]
        else
          (Array.wrap(first_element) + Array.wrap(second_element)).uniq
        end
      end

      def crushable?(element)
        element.is_a?(Hash) || element.is_a?(Array)
      end

      def crush_hash(hash)
        hash.flat_map do |key, value|
          crushed_value = crushable?(value) ? crush(value) : value
          Array.wrap(key) + Array.wrap(crushed_value)
        end
      end

      def crush_array(array)
        array.flat_map do |element|
          crushable?(element) ? crush(element) : element
        end
      end
    end
  end
end
