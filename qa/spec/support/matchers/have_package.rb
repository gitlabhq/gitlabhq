# frozen_string_literal: true

module Matchers
  module HavePackage
    RSpec::Matchers.define :have_package do |package|
      match do |page_object|
        page_object.has_package?(package)
      end

      match_when_negated do |page_object|
        page_object.has_no_package?(package)
      end
    end
  end
end
