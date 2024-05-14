# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NumbersHelper do
  describe '#limited_counter_with_delimiter' do
    using RSpec::Parameterized::TableSyntax

    subject { limited_counter_with_delimiter(resource, **options) }

    where(:count, :options, :expected_result) do
      # Zero handling
      0    | {}                      | '0'
      0    | { include_zero: true }  | '0'
      0    | { include_zero: false } | nil

      # Using explicit limit
      9    | { limit: 10 } | '9'
      10   | { limit: 10 } | '10'
      11   | { limit: 10 } | '10+'
      12   | { limit: 10 } | '10+'
      # Using default limit
      999  | {}            | '999'
      1000 | {}            | '1,000'
      1001 | {}            | '1,000+'
      1002 | {}            | '1,000+'
    end

    with_them do
      let(:page) { double('page', total_count_with_limit: [count, options.fetch(:limit, 1000) + 1].min) }
      let(:resource) { class_double(Ci::Runner, page: page) }

      it { is_expected.to eq(expected_result) }
    end
  end
end
