# frozen_string_literal: true

require_relative '../../tooling/danger/cookie_setting'

module Danger
  class CookieSetting < ::Danger::Plugin
    def add_suggestions_for(filename)
      Tooling::Danger::CookieSetting.new(filename, context: self).suggest
    end
  end
end
