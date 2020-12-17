# frozen_string_literal: true

module Matchers
  module HaveSnippetDescription
    RSpec::Matchers.define :have_snippet_description do |description|
      match do |page_object|
        page_object.has_snippet_description?(description)
      end

      match_when_negated do |page_object|
        page_object.has_no_snippet_description?
      end
    end
  end
end
