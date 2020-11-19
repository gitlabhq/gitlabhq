# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AlertManagementIntegrationType'] do
  specify { expect(described_class.graphql_name).to eq('AlertManagementIntegrationType') }

  describe 'statuses' do
    using RSpec::Parameterized::TableSyntax

    where(:name, :value) do
      'PROMETHEUS'    | :prometheus
      'HTTP'          | :http
    end

    with_them do
      it 'exposes a type with the correct value' do
        expect(described_class.values[name].value).to eq(value)
      end
    end
  end
end
