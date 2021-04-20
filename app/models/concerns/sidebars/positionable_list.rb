# frozen_string_literal: true

# This module handles elements in a list. All elements
# must have a different class
module Sidebars
  module PositionableList
    def add_element(list, element)
      list << element
    end

    def insert_element_before(list, before_element, new_element)
      index = index_of(list, before_element)

      if index
        list.insert(index, new_element)
      else
        list.unshift(new_element)
      end
    end

    def insert_element_after(list, after_element, new_element)
      index = index_of(list, after_element)

      if index
        list.insert(index + 1, new_element)
      else
        add_element(list, new_element)
      end
    end

    private

    def index_of(list, element)
      list.index { |e| e.is_a?(element) }
    end
  end
end
