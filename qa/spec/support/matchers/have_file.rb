# frozen_string_literal: true

module Matchers
  module HaveFile
    RSpec::Matchers.define :have_file do |file|
      match do |page_object|
        page_object.has_file?(file)
      end

      match_when_negated do |page_object|
        page_object.has_no_file?(file)
      end
    end
  end
end
