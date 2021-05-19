# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::TemplateType do
  specify { expect(described_class.graphql_name).to eq('CiTemplate') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      content
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
