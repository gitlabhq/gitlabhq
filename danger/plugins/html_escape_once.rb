# frozen_string_literal: true

require_relative '../../tooling/danger/html_escape_once'

module Danger
  class HtmlEscapeOnce < ::Danger::Plugin
    include Tooling::Danger::HtmlEscapeOnce
  end
end
