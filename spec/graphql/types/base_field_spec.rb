# frozen_string_literal: true

require 'spec_helper'

describe Types::BaseField do
  context 'when considering complexity' do
    let(:resolver) do
      Class.new(described_class) do
        def self.resolver_complexity(args, child_complexity:)
          2 if args[:foo]
        end

        def self.complexity_multiplier(args)
          0.01
        end
      end
    end

    it 'defaults to 1' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true)

      expect(field.to_graphql.complexity).to eq 1
    end

    describe '#base_complexity' do
      context 'with no gitaly calls' do
        it 'defaults to 1' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true)

          expect(field.base_complexity).to eq 1
        end
      end

      context 'with a gitaly call' do
        it 'adds 1 to the default value' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true)

          expect(field.base_complexity).to eq 2
        end
      end
    end

    it 'has specified value' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, complexity: 12)

      expect(field.to_graphql.complexity).to eq 12
    end

    context 'when field has a resolver proc' do
      context 'and is a connection' do
        let(:field) { described_class.new(name: 'test', type: GraphQL::STRING_TYPE.connection_type, resolver_class: resolver, max_page_size: 100, null: true) }

        it 'sets complexity depending on arguments for resolvers' do
          expect(field.to_graphql.complexity.call({}, {}, 2)).to eq 4
          expect(field.to_graphql.complexity.call({}, { first: 50 }, 2)).to eq 3
        end

        it 'sets complexity depending on number load limits for resolvers' do
          expect(field.to_graphql.complexity.call({}, { first: 1 }, 2)).to eq 2
          expect(field.to_graphql.complexity.call({}, { first: 1, foo: true }, 2)).to eq 4
        end
      end

      context 'and is not a connection' do
        it 'sets complexity as normal' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: resolver, max_page_size: 100, null: true)

          expect(field.to_graphql.complexity.call({}, {}, 2)).to eq 2
          expect(field.to_graphql.complexity.call({}, { first: 50 }, 2)).to eq 2
        end
      end
    end

    context 'calls_gitaly' do
      context 'for fields with a resolver' do
        it 'adds 1 if true' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true)

          expect(field.to_graphql.complexity).to eq 2
        end
      end

      context 'for fields without a resolver' do
        it 'adds 1 if true' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true)

          expect(field.to_graphql.complexity).to eq 2
        end
      end

      it 'defaults to false' do
        field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true)

        expect(field.base_complexity).to eq Types::BaseField::DEFAULT_COMPLEXITY
      end

      it 'is overridden by declared complexity value' do
        field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true, complexity: 12)

        expect(field.to_graphql.complexity).to eq 12
      end
    end

    describe '#calls_gitaly_check' do
      let(:gitaly_field) { described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true) }
      let(:no_gitaly_field) { described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: false) }

      context 'if there are no Gitaly calls' do
        before do
          allow(Gitlab::GitalyClient).to receive(:get_request_count).and_return(0)
        end

        it 'does not raise an error if calls_gitaly is false' do
          expect { no_gitaly_field.send(:calls_gitaly_check) }.not_to raise_error
        end

        it 'raises an error if calls_gitaly: true appears' do
          expect { gitaly_field.send(:calls_gitaly_check) }.to raise_error(/please add `calls_gitaly: true`/)
        end
      end

      context 'if there is at least 1 Gitaly call' do
        before do
          allow(Gitlab::GitalyClient).to receive(:get_request_count).and_return(1)
        end

        it 'does not raise an error if calls_gitaly is true' do
          expect { gitaly_field.send(:calls_gitaly_check) }.not_to raise_error
        end

        it 'raises an error if calls_gitaly is not decalared' do
          expect { no_gitaly_field.send(:calls_gitaly_check) }.to raise_error(/please remove `calls_gitaly: true`/)
        end
      end
    end
  end
end
