# frozen_string_literal: true

require 'spec_helper'

describe 'Group value stream analytics' do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  RSpec::Matchers.define :have_pushed_frontend_feature_flags do |expected|
    def to_js(key, value)
      "\"#{key}\":#{value}"
    end

    match do |actual|
      expected.all? do |feature_flag_name, enabled|
        page.html.include?(to_js(feature_flag_name, enabled))
      end
    end

    failure_message do |actual|
      missing = expected.select do |feature_flag_name, enabled|
        !page.html.include?(to_js(feature_flag_name, enabled))
      end

      formatted_missing_flags = missing.map { |feature_flag_name, enabled| to_js(feature_flag_name, enabled) }.join("\n")

      "The following feature flag(s) cannot be found in the frontend HTML source: #{formatted_missing_flags}"
    end
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_owner(user)

    sign_in(user)
  end

  it 'pushes frontend feature flags' do
    visit group_analytics_cycle_analytics_path(group)

    expect(page).to have_pushed_frontend_feature_flags(
      cycleAnalyticsScatterplotEnabled: true,
      cycleAnalyticsScatterplotMedianEnabled: true,
      valueStreamAnalyticsPathNavigation: true
    )
  end

  context 'when `value_stream_analytics_path_navigation` is disabled for a group' do
    before do
      stub_feature_flags(value_stream_analytics_path_navigation: false, thing: group)
    end

    it 'pushes disabled feature flag to the frontend' do
      visit group_analytics_cycle_analytics_path(group)

      expect(page).to have_pushed_frontend_feature_flags(valueStreamAnalyticsPathNavigation: false)
    end
  end
end
