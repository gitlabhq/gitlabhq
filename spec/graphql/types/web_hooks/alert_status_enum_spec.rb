# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WebhookAlertStatus'], feature_category: :importers do
  specify { expect(described_class.graphql_name).to eq('WebhookAlertStatus') }

  describe 'auto-disabling statuses' do
    using RSpec::Parameterized::TableSyntax

    where(:graphql_value, :param_value) do
      'EXECUTABLE'              | 'executable'
      'TEMPORARILY_DISABLED'    | 'temporarily_disabled'
      'DISABLED'                | 'disabled'
    end

    with_them do
      it 'exposes status with the correct value' do
        expect(described_class.values[graphql_value].value).to eq(param_value)
      end
    end
  end
end
