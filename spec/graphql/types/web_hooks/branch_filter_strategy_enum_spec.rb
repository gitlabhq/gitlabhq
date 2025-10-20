# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WebhookBranchFilterStrategy'], feature_category: :importers do
  specify { expect(described_class.graphql_name).to eq('WebhookBranchFilterStrategy') }

  describe 'branch filter strategies' do
    using RSpec::Parameterized::TableSyntax

    where(:graphql_value, :param_value) do
      'WILDCARD'     | 'wildcard'
      'REGEX'        | 'regex'
      'ALL_BRANCHES' | 'all_branches'
    end

    with_them do
      it 'exposes the strategy with the correct value' do
        expect(described_class.values[graphql_value].value).to eq(param_value)
      end
    end
  end
end
