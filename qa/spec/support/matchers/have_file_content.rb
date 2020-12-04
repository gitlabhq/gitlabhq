# frozen_string_literal: true

module Matchers
  module HaveFileContent
    RSpec::Matchers.define :have_file_content do |file_content, file_number|
      match do |page_object|
        page_object.has_file_content?(file_content, file_number)
      end

      match_when_negated do |page_object|
        page_object.has_no_file_content?(file_content, file_number)
      end
    end
  end
end
