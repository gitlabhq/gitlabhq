# frozen_string_literal: true

# This module handles element positions in a list.
module Sidebars
  module Concerns
    module PositionableList
      def add_element(list, element)
        return unless element

        list << element
      end

      def insert_element_before(list, before_element, new_element)
        return unless new_element

        index = index_of(list, before_element)

        if index
          list.insert(index, new_element)
        else
          list.unshift(new_element)
        end
      end

      def insert_element_after(list, after_element, new_element)
        return unless new_element

        index = index_of(list, after_element)

        if index
          list.insert(index + 1, new_element)
        else
          add_element(list, new_element)
        end
      end

      def replace_element(list, element_to_replace, new_element)
        return unless new_element

        index = index_of(list, element_to_replace)

        return unless index

        list[index] = new_element
      end

      def remove_element(list, element_to_remove)
        index = index_of(list, element_to_remove)

        return unless index

        list.slice!(index)
      end

      private

      # Classes including this method will have to define
      # the way to identify elements through this method
      def index_of(list, element)
        raise NotImplementedError
      end
    end
  end
end
