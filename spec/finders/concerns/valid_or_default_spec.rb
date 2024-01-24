# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ValidOrDefault, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:object) do
    Class.new do
      include ValidOrDefault
    end.new
  end

  let(:valid_values) { %w[a b c] }
  let(:default_value) { 'a' }

  describe '.valid_or_default' do
    where(:value, :output) do
      'a' | 'a'
      'b' | 'b'
      'c'       | 'c'
      'invalid' | 'a'
      nil       | 'a'
    end

    with_them do
      it 'returns value if value is valid otherwise default' do
        expect(object.valid_or_default(value, valid_values, default_value)).to be(output)
      end
    end
  end
end
