# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UserFirstDayOfWeek'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('UserFirstDayOfWeek') }

  it 'exposes the days the preferences page offers' do
    expect(described_class.values.keys).to match_array(%w[SUNDAY MONDAY SATURDAY])
  end

  it 'maps the days to the stored integers' do
    expect(described_class.values['SUNDAY'].value).to eq(0)
    expect(described_class.values['MONDAY'].value).to eq(1)
    expect(described_class.values['SATURDAY'].value).to eq(6)
  end
end
