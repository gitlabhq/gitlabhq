# frozen_string_literal: true

module Matchers
  module HaveDesign
    RSpec::Matchers.define :have_design do |design|
      match do |page_object|
        page_object.has_design?(design)
      end

      match_when_negated do |page_object|
        page_object.has_no_design?(design)
      end
    end
  end
end
