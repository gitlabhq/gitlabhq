# frozen_string_literal: true

RSpec.configure do |config|
  config.define_derived_metadata(file_path: Regexp.new('spec/thor/')) do |metadata|
    metadata[:type] = :thor
  end

  # Set terminal columns to be 120, so all specs behave the same no matter where it is being tested
  config.before(:each, type: :thor) { stub_env('THOR_COLUMNS', 120) }
end
