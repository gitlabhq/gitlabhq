# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UntrustedRegexp'] do
  using RSpec::Parameterized::TableSyntax

  specify { expect(described_class.graphql_name).to eq('UntrustedRegexp') }

  specify { expect(described_class.description).to eq('A regexp containing patterns sourced from user input') }

  describe '.coerce_input' do
    subject { described_class.coerce_input(input, nil) }

    where(:input, :expected_result) do
      '.*'       | '.*'
      '(.*)'     | '(.*)'
      '[test*]+' | '[test*]+'
      '*v1'      | :raise_error
      '[test*'   | :raise_error
      'test*+'   | :raise_error
    end

    with_them do
      context "with input #{params[:input]}" do
        if params[:expected_result] == :raise_error
          it 'raises a coercion error' do
            expect { subject }.to raise_error(GraphQL::CoercionError, /#{Regexp.quote(input)} is an invalid regexp/)
          end
        else
          it { expect(subject).to eq(expected_result) }
        end
      end
    end
  end

  describe '.coerce_result' do
    subject { described_class.coerce_result(input, nil) }

    where(:input, :expected_result) do
      '1'  | '1'
      1    | '1'
      true | 'true'
    end

    with_them do
      context "with input #{params[:input]}" do
        it { expect(subject).to eq(expected_result) }
      end
    end
  end
end
