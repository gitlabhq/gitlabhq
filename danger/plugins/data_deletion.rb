# frozen_string_literal: true

require_relative '../../tooling/danger/data_deletion'

module Danger
  class DataDeletion < ::Danger::Plugin
    include Tooling::Danger::DataDeletion
  end
end
