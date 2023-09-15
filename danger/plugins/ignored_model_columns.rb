# frozen_string_literal: true

require_relative '../../tooling/danger/ignored_model_columns'

module Danger
  class IgnoredModelColumns < ::Danger::Plugin
    include Tooling::Danger::IgnoredModelColumns
  end
end
