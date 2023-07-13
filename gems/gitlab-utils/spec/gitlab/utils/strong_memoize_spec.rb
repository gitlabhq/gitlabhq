# frozen_string_literal: true

require 'spec_helper'
require 'active_support/testing/time_helpers'

RSpec.describe Gitlab::Utils::StrongMemoize, feature_category: :shared do
  include ActiveSupport::Testing::TimeHelpers

  let(:klass) do
    strong_memoize_class = described_class

    Struct.new(:value) do
      include strong_memoize_class

      def self.method_added_list
        @method_added_list ||= []
      end

      def self.method_added(name)
        method_added_list << name
      end

      def method_name
        strong_memoize(:method_name) do # rubocop:disable Gitlab/StrongMemoizeAttr
          trace << value
          value
        end
      end

      def method_name_with_expiration
        strong_memoize_with_expiration(:method_name_with_expiration, 1) do
          trace << value
          value
        end
      end

      def method_name_attr
        trace << value
        value
      end
      strong_memoize_attr :method_name_attr

      def enabled?
        trace << value
        value
      end
      strong_memoize_attr :enabled?

      def method_name_with_args(*args)
        strong_memoize_with(:method_name_with_args, args) do
          trace << [value, args]
          value
        end
      end

      def trace
        @trace ||= []
      end

      protected

      def private_method; end
      private :private_method
      strong_memoize_attr :private_method

      public

      def protected_method; end
      protected :protected_method
      strong_memoize_attr :protected_method

      private

      def public_method; end
      public :public_method
      strong_memoize_attr :public_method
    end
  end

  subject(:object) { klass.new(value) }

  shared_examples 'caching the value' do
    let(:member_name) { described_class.normalize_key(method_name) }

    it 'only calls the block once' do
      value0 = object.public_send(method_name)
      value1 = object.public_send(method_name)

      expect(value0).to eq(value)
      expect(value1).to eq(value)
      expect(object.trace).to contain_exactly(value)
    end

    it 'returns and defines the instance variable for the exact value' do
      returned_value = object.public_send(method_name)
      memoized_value = object.instance_variable_get(:"@#{member_name}")

      expect(returned_value).to eql(value)
      expect(memoized_value).to eql(value)
    end
  end

  describe '#strong_memoize' do
    [nil, false, true, 'value', 0, [0]].each do |value|
      context "with value #{value}" do
        let(:value) { value }
        let(:method_name) { :method_name }

        it_behaves_like 'caching the value'

        it 'raises exception for invalid type as key' do
          expect { object.strong_memoize(10) { 20 } }.to raise_error(/Invalid type of '10'/)
        end

        it 'raises exception for invalid characters in key' do
          expect { object.strong_memoize(:enabled?) { 20 } }
            .to raise_error(/is not allowed as an instance variable name/)
        end
      end
    end

    context "with memory allocation", type: :benchmark do
      let(:value) { 'aaa' }

      before do
        object.method_name # warmup
      end

      [:method_name, "method_name"].each do |argument|
        context "when argument is a #{argument.class}" do
          it 'does allocate exactly one string when fetching value' do
            expect do
              object.strong_memoize(argument) { 10 }
            end.to perform_allocation(1)
          end

          it 'does allocate exactly one string when storing value' do
            object.clear_memoization(:method_name) # clear to force set

            expect do
              object.strong_memoize(argument) { 10 }
            end.to perform_allocation(1)
          end
        end
      end
    end
  end

  describe '#strong_memoize_with_expiration' do
    [nil, false, true, 'value', 0, [0]].each do |value|
      context "with value #{value}" do
        let(:value) { value }
        let(:method_name) { :method_name_with_expiration }

        it_behaves_like 'caching the value'

        it 'raises exception for invalid type as key' do
          expect { object.strong_memoize_with_expiration(10, 1) { 20 } }.to raise_error(/Invalid type of '10'/)
        end

        it 'raises exception for invalid characters in key' do
          expect { object.strong_memoize_with_expiration(:enabled?, 1) { 20 } }
            .to raise_error(/is not allowed as an instance variable name/)
        end
      end
    end

    context 'with value memoization test' do
      let(:value) { 'value' }

      it 'caches the value for specified number of seconds' do
        object.method_name_with_expiration
        object.method_name_with_expiration

        expect(object.trace.count).to eq(1)

        travel_to(Time.current + 2.seconds) do
          object.method_name_with_expiration

          expect(object.trace.count).to eq(2)
        end
      end
    end
  end

  describe '#strong_memoize_with' do
    [nil, false, true, 'value', 0, [0]].each do |value|
      context "with value #{value}" do
        let(:value) { value }

        it 'only calls the block once' do
          value0 = object.method_name_with_args(1)
          value1 = object.method_name_with_args(1)
          value2 = object.method_name_with_args([2, 3])
          value3 = object.method_name_with_args([2, 3])

          expect(value0).to eq(value)
          expect(value1).to eq(value)
          expect(value2).to eq(value)
          expect(value3).to eq(value)

          expect(object.trace).to contain_exactly([value, [1]], [value, [[2, 3]]])
        end

        it 'returns and defines the instance variable for the exact value' do
          returned_value = object.method_name_with_args(1, 2, 3)
          memoized_value = object.instance_variable_get(:@method_name_with_args)

          expect(returned_value).to eql(value)
          expect(memoized_value).to eql({ [[1, 2, 3]] => value })
        end
      end
    end
  end

  describe '#strong_memoized?' do
    shared_examples 'memoization check' do |method_name|
      context "when method is :#{method_name}" do
        let(:value) { :anything }

        subject { object.strong_memoized?(method_name) }

        it 'returns false if the value is uncached' do
          expect(subject).to be(false)
        end

        it 'returns true if the value is cached' do
          object.public_send(method_name)

          expect(subject).to be(true)
        end
      end
    end

    it_behaves_like 'memoization check', :method_name
    it_behaves_like 'memoization check', :enabled?
  end

  describe '#clear_memoization' do
    shared_examples 'clearing memoization' do |method_name|
      let(:member_name) { described_class.normalize_key(method_name) }
      let(:value) { 'mepmep' }

      it 'removes the instance variable' do
        object.public_send(method_name)

        object.clear_memoization(method_name)

        expect(object.instance_variable_defined?(:"@#{member_name}")).to be(false)
      end
    end

    it_behaves_like 'clearing memoization', :method_name
    it_behaves_like 'clearing memoization', :enabled?
  end

  describe '.strong_memoize_attr' do
    [nil, false, true, 'value', 0, [0]].each do |value|
      context "with value '#{value}'" do
        let(:value) { value }

        context 'with memoized after method definition' do
          let(:method_name) { :method_name_attr }

          it_behaves_like 'caching the value'

          it 'calls the existing .method_added' do
            expect(klass.method_added_list).to include(:method_name_attr)
          end

          it 'retains method arity' do
            expect(klass.instance_method(method_name).arity).to eq(0)
          end
        end
      end
    end

    describe 'method visibility' do
      it 'sets private visibility' do
        expect(klass.private_instance_methods).to include(:private_method)
        expect(klass.protected_instance_methods).not_to include(:private_method)
        expect(klass.public_instance_methods).not_to include(:private_method)
      end

      it 'sets protected visibility' do
        expect(klass.private_instance_methods).not_to include(:protected_method)
        expect(klass.protected_instance_methods).to include(:protected_method)
        expect(klass.public_instance_methods).not_to include(:protected_method)
      end

      it 'sets public visibility' do
        expect(klass.private_instance_methods).not_to include(:public_method)
        expect(klass.protected_instance_methods).not_to include(:public_method)
        expect(klass.public_instance_methods).to include(:public_method)
      end
    end

    context "when method doesn't exist" do
      let(:klass) do
        strong_memoize_class = described_class

        Struct.new(:value) do
          include strong_memoize_class
        end
      end

      subject { klass.strong_memoize_attr(:nonexistent_method) }

      it 'fails when strong-memoizing a nonexistent method' do
        expect { subject }.to raise_error(NameError, /undefined method `nonexistent_method' for class/)
      end
    end

    context 'when memoized method has parameters' do
      it 'raises an error' do
        expected_message = /Using `strong_memoize_attr` on methods with parameters is not supported/

        expect do
          strong_memoize_class = described_class

          Class.new do
            include strong_memoize_class

            def method_with_parameters(params); end
            strong_memoize_attr :method_with_parameters
          end
        end.to raise_error(RuntimeError, expected_message)
      end
    end
  end

  describe '.normalize_key' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.normalize_key(input) }

    where(:input, :output, :valid) do
      :key    | :key    | true
      "key"   | "key"   | true
      :key?   | "key？" | true
      "key?"  | "key？" | true
      :key!   | "key！" | true
      "key!"  | "key！" | true
      # invalid cases caught elsewhere
      :"ke?y" | :"ke?y" | false
      "ke?y"  | "ke?y"  | false
      :"ke!y" | :"ke!y" | false
      "ke!y"  | "ke!y"  | false
    end

    with_them do
      let(:ivar) { "@#{output}" }

      it { is_expected.to eq(output) }

      if params[:valid]
        it 'is a valid ivar name' do
          expect { instance_variable_defined?(ivar) }.not_to raise_error
        end
      else
        it 'raises a NameError error' do
          expect { instance_variable_defined?(ivar) }
            .to raise_error(NameError, /not allowed as an instance/)
        end
      end
    end
  end
end
