# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/keep'
require 'gitlab/housekeeper/change'
require 'rspec/parameterized'

RSpec.describe ::Gitlab::Housekeeper::Keep do
  let(:test_keep_class) do
    Class.new(described_class) do
      def each_identified_change
        yield ::Gitlab::Housekeeper::Change.new
      end

      def make_change!(change)
        change
      end
    end
  end

  let(:keep_instance) { test_keep_class.new }

  describe '#should_push_code?' do
    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands -- binary operator is used in parameterized table
    where(:has_conflicts, :push_when_conflict, :already_approved, :push_when_approved, :code_update_required,
      :expected_result) do
      true  | true  | true  | false | false | true
      true  | true  | false | false | false | true
      true  | false | true  | false | false | false
      true  | false | false | false | true  | true
      false | true  | true  | false | true  | false
      false | true  | true  | false | false | false
      false | true  | true  | true  | true  | true
      false | true  | true  | true  | false | false
      false | true  | false | true  | true  | true
      false | true  | false | true  | false | false
    end
    # rubocop:enable Lint/BinaryOperatorWithIdenticalOperands

    with_them do
      it "determines if we should push" do
        change = instance_double(::Gitlab::Housekeeper::Change)

        allow(change).to receive(:has_conflicts).and_return(has_conflicts)
        allow(change).to receive(:already_approved?).and_return(already_approved)
        allow(change).to receive(:update_required?).with(:code).and_return(code_update_required)

        result = keep_instance.should_push_code?(change, push_when_approved, push_when_conflict: push_when_conflict)
        expect(result).to eq(expected_result)
      end
    end
  end

  describe '#matches_filter_identifiers?' do
    context 'when filter_identifiers is nil' do
      it 'returns true' do
        expect(keep_instance.matches_filter_identifiers?(%w[any identifier])).to be true
      end
    end

    context 'when filter_identifiers is set' do
      let(:filter_identifiers) { instance_double(::Gitlab::Housekeeper::FilterIdentifiers) }
      let(:keep_instance) { test_keep_class.new(filter_identifiers: filter_identifiers) }

      it 'delegates to filter_identifiers' do
        allow(filter_identifiers).to receive(:matches_filters?).with(['test']).and_return(true)

        expect(keep_instance.matches_filter_identifiers?(['test'])).to be true
      end
    end
  end
end
