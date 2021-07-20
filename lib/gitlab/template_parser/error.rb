# frozen_string_literal: true

module Gitlab
  module TemplateParser
    # An error raised when a template couldn't be rendered.
    Error = Class.new(StandardError)
  end
end
