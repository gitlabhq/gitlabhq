# frozen_string_literal: true

require_relative '../../tooling/danger/datateam'

module Danger
  class Datateam < ::Danger::Plugin
    include Tooling::Danger::Datateam
  end
end
