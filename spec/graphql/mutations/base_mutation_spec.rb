# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Mutations::BaseMutation do
  include GraphqlHelpers

  describe 'argument nullability' do
    let_it_be(:user) { create(:user) }
    let_it_be(:context)  { { current_user: user } }

    subject(:mutation) { mutation_class.new(object: nil, context: context, field: nil) }

    describe 'when using a mutation with correct argument declarations' do
      context 'when argument is nullable and required' do
        let(:mutation_class) do
          Class.new(described_class) do
            graphql_name 'BaseMutation'
            argument :foo, GraphQL::Types::String, required: :nullable
          end
        end

        specify do
          expect { subject.ready? }.to raise_error(ArgumentError, /must be provided: foo/)
        end

        specify do
          expect { subject.ready?(foo: nil) }.not_to raise_error
        end

        specify do
          expect { subject.ready?(foo: "bar") }.not_to raise_error
        end
      end

      context 'when argument is required and NOT nullable' do
        let(:mutation_class) do
          Class.new(described_class) do
            graphql_name 'BaseMutation'
            argument :foo, GraphQL::Types::String, required: true
          end
        end

        specify do
          expect { subject.ready? }.to raise_error(ArgumentError, /must be provided/)
        end

        specify do
          expect { subject.ready?(foo: nil) }.to raise_error(ArgumentError, /must be provided/)
        end

        specify do
          expect { subject.ready?(foo: "bar") }.not_to raise_error
        end
      end
    end
  end
end
