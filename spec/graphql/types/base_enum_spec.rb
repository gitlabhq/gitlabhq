# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseEnum do
  describe '.from_rails_enum' do
    let(:enum_type) { Class.new(described_class) }
    let(:template) { "The name is '%{name}', James %{name}." }

    let(:enum) do
      {
        'foo' => 1,
        'bar' => 2,
        'baz' => 100
      }
    end

    it 'contructs the correct values' do
      enum_type.from_rails_enum(enum, description: template)

      expect(enum_type.values).to match(
        'FOO' => have_attributes(
          description: "The name is 'foo', James foo.",
          value: 'foo'
        ),
        'BAR' => have_attributes(
          description: "The name is 'bar', James bar.",
          value: 'bar'
        ),
        'BAZ' => have_attributes(
          description: "The name is 'baz', James baz.",
          value: 'baz'
        )
      )
    end
  end

  describe '.declarative_enum' do
    let(:use_name) { true }
    let(:use_description) { true }
    let(:enum_type) do
      Class.new(described_class) do
        graphql_name 'OriginalName'
        description 'Original description'
      end
    end

    let(:enum_module) do
      Module.new do
        extend DeclarativeEnum

        name 'Name'
        description 'Description'

        define do
          foo value: 0, description: 'description of foo'
        end
      end
    end

    subject(:set_declarative_enum) do
      enum_type.declarative_enum(enum_module, use_name: use_name, use_description: use_description)
    end

    describe '#graphql_name' do
      context 'when the use_name is `true`' do
        it 'changes the graphql_name' do
          expect { set_declarative_enum }
            .to change(enum_type, :graphql_name).from('OriginalName').to('Name')
        end
      end

      context 'when the use_name is `false`' do
        let(:use_name) { false }

        it 'does not change the graphql_name' do
          expect { set_declarative_enum }
            .not_to change(enum_type, :graphql_name).from('OriginalName')
        end
      end
    end

    describe '#description' do
      context 'when the use_description is `true`' do
        it 'changes the description' do
          expect { set_declarative_enum }
            .to change(enum_type, :description).from('Original description').to('Description')
        end
      end

      context 'when the use_description is `false`' do
        let(:use_description) { false }

        it 'does not change the description' do
          expect { set_declarative_enum }
            .not_to change(enum_type, :description).from('Original description')
        end
      end
    end

    describe '#values' do
      it 'sets the values defined by the declarative enum' do
        set_declarative_enum

        expect(enum_type.values.keys).to eq(['FOO'])
        expect(enum_type.values.values.map(&:description)).to eq(['description of foo'])
        expect(enum_type.values.values.map(&:value)).to eq([0])
      end
    end
  end

  describe '.enum' do
    let(:enum) do
      Class.new(described_class) do
        value 'TEST', value: 3
        value 'other'
        value 'NORMAL'
      end
    end

    it 'adds all enum values to #enum' do
      expect(enum.enum.keys).to contain_exactly('test', 'other', 'normal')
      expect(enum.enum.values).to contain_exactly(3, 'other', 'NORMAL')
    end

    it 'is a HashWithIndefferentAccess' do
      expect(enum.enum).to be_a(HashWithIndifferentAccess)
    end
  end

  include_examples 'Gitlab-style deprecations' do
    def subject(args = {})
      enum = Class.new(described_class) do
        graphql_name 'TestEnum'

        value 'TEST_VALUE', **args
      end

      enum.to_graphql.values['TEST_VALUE']
    end
  end
end
