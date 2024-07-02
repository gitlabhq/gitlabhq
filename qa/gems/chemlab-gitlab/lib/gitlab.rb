# frozen_string_literal: true

require 'chemlab/library'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__)
loader.ignore("#{__dir__}/gitlab/**/*.stub.rb") # ignore page stubs
loader.setup

# Chemlab Page Libraries for GitLab
module Gitlab
  include Chemlab::Library
end
