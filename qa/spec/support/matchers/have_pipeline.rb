# frozen_string_literal: true

module Matchers
  module HavePipeline
    RSpec::Matchers.define :have_pipeline do
      match do |page_object|
        page_object.has_pipeline?
      end

      match_when_negated do |page_object|
        page_object.has_no_pipeline?
      end
    end
  end
end
