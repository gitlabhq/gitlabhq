# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ErrorTrackingStatus'], feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('ErrorTrackingStatus') }

  describe 'enum values' do
    using RSpec::Parameterized::TableSyntax

    where(:field_name, :field_value) do
      'SUCCESS'   | :success
      'ERROR'     | :error
      'NOT_FOUND' | :not_found
      'RETRY'     | :retry
    end

    with_them do
      it 'exposes correct available fields' do
        expect(described_class.values[field_name].value).to eq(field_value)
      end
    end
  end
end
