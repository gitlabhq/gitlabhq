# frozen_string_literal: true
require 'spec_helper'

describe 'User edit preferences profile' do
  let(:user) { create(:user) }

  before do
    stub_feature_flags(user_time_settings: true)
    sign_in(user)
    visit(profile_preferences_path)
  end

  it 'allows the user to toggle their time format preference' do
    field = page.find_field("user[time_format_in_24h]")

    expect(field).not_to be_checked

    field.click

    expect(field).to be_checked
  end

  it 'allows the user to toggle their time display preference' do
    field = page.find_field("user[time_display_relative]")

    expect(field).to be_checked

    field.click

    expect(field).not_to be_checked
  end
end
