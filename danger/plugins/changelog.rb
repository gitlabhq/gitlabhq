# frozen_string_literal: true

require_relative '../../lib/gitlab/danger/changelog'

module Danger
  class Changelog < Plugin
    # Put the helper code somewhere it can be tested
    include Gitlab::Danger::Changelog
  end
end
