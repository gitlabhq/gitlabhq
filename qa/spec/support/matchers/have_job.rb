# frozen_string_literal: true

module Matchers
  module HaveJob
    RSpec::Matchers.define :have_job do |job|
      match do |page_object|
        page_object.has_job?(job)
      end

      match_when_negated do |page_object|
        page_object.has_no_job?(job)
      end
    end
  end
end
