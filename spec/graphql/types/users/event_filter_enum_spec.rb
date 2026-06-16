# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UserEventFilter'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('UserEventFilter') }

  it 'exposes the same filters as EventFilter' do
    expected = %w[ALL PUSH MERGED ISSUE COMMENTS TEAM WIKI DESIGNS]

    expect(described_class.values.keys).to include(*expected)
  end

  it 'maps enum values to EventFilter constants' do
    expect(described_class.values['ALL'].value).to eq(::EventFilter::ALL)
    expect(described_class.values['PUSH'].value).to eq(::EventFilter::PUSH)
    expect(described_class.values['MERGED'].value).to eq(::EventFilter::MERGED)
    expect(described_class.values['ISSUE'].value).to eq(::EventFilter::ISSUE)
    expect(described_class.values['COMMENTS'].value).to eq(::EventFilter::COMMENTS)
    expect(described_class.values['TEAM'].value).to eq(::EventFilter::TEAM)
    expect(described_class.values['WIKI'].value).to eq(::EventFilter::WIKI)
    expect(described_class.values['DESIGNS'].value).to eq(::EventFilter::DESIGNS)
  end
end
