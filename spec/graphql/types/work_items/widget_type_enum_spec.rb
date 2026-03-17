# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WorkItemWidgetType'] do
  specify { expect(described_class.graphql_name).to eq('WorkItemWidgetType') }

  it 'exposes all the existing widget type values' do
    expect(described_class.values.transform_values { |v| v.value }).to include(
      'DESCRIPTION' => :description
    )
  end
end
