# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeZoneHelper, '(JavaScript fixtures)' do
  include JavaScriptFixturesHelpers
  include TimeZoneHelper

  let(:response) { @timezones.sort_by! { |tz| tz[:name] }.to_json }

  it 'timezones/short.json' do
    @timezones = timezone_data(format: :short)
  end

  it 'timezones/full.json' do
    @timezones = timezone_data(format: :full)
  end
end
