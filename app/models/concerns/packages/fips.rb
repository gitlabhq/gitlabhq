# rubocop:disable Naming/FileName
# frozen_string_literal: true

module Packages
  module FIPS
    extend ActiveSupport::Concern

    DisabledError = Class.new(StandardError)
  end
end
# rubocop:enable Naming/FileName
