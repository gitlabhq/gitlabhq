# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['OrganizationUserBadge'], feature_category: :cell do
  let(:expected_fields) { %w[text variant] }

  specify { expect(described_class.graphql_name).to eq('OrganizationUserBadge') }
  specify { expect(described_class).to have_graphql_fields(*expected_fields) }
end
