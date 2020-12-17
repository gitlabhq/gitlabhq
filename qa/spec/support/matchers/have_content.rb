# frozen_string_literal: true

module Matchers
  module HaveContent
    RSpec::Matchers.define :have_content do |content|
      match do |page_object|
        page_object.has_content?(content)
      end

      match_when_negated do |page_object|
        page_object.has_no_content?(content)
      end
    end
  end
end
