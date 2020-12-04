# frozen_string_literal: true

module Matchers
  module HaveElement
    RSpec::Matchers.define :have_element do |element, **kwargs|
      match do |page_object|
        page_object.has_element?(element, **kwargs)
      end

      match_when_negated do |page_object|
        page_object.has_no_element?(element, **kwargs)
      end
    end
  end
end
