# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AbuseReport'], feature_category: :insider_threat do
  let(:fields) { %w[id labels discussions notes] }

  specify { expect(described_class.graphql_name).to eq('AbuseReport') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
