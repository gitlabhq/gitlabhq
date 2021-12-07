# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeZoneHelper, '(JavaScript fixtures)' do
  include JavaScriptFixturesHelpers
  include TimeZoneHelper

  let(:response) { @timezones.sort_by! { |tz| tz[:name] }.to_json }

  %I[short abbr full].each do |format|
    it "timezones/#{format}.json" do
      @timezones = timezone_data(format: format)
    end
  end
end
