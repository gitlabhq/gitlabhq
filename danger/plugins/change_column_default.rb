# frozen_string_literal: true

require_relative '../../tooling/danger/change_column_default'

module Danger
  class ChangeColumnDefault < ::Danger::Plugin
    include Tooling::Danger::ChangeColumnDefault
  end
end
