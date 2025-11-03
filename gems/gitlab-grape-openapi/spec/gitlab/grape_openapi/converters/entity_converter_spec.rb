# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::EntityConverter do
  let(:schema_registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }
  let(:converter) { described_class.new(entity_class, schema_registry) }

  before do
    allow_any_instance_of(Class).to receive(:name).and_return('TestEntities::UserEntity')
  end

  describe '#convert' do
    subject(:converted_schema) { converter.convert }

    shared_examples 'converts to expected schema' do |expected_properties|
      it 'outputs properties correctly' do
        expect(converted_schema.properties).to eq(expected_properties)
      end
    end

    shared_examples 'adds schema to registry' do
      it 'adds a new schema to the registry' do
        converted_schema
        expect(converter.schema_registry.schemas.count).to eq(1)
      end
    end

    context 'with basic exposures' do
      context 'with no detail' do
        let(:entity_class) do
          Class.new(Grape::Entity) do
            expose :id
          end
        end

        include_examples 'converts to expected schema', { id: { type: "string" } }
        include_examples 'adds schema to registry'
      end

      context 'with as directive' do
        let(:entity_class) do
          Class.new(Grape::Entity) do
            expose :name, as: :full_name
          end
        end

        include_examples 'converts to expected schema', { full_name: { type: "string" } }
      end

      context 'with default value' do
        let(:entity_class) do
          Class.new(Grape::Entity) do
            expose :email, default: "example@gitlab.com"
          end
        end

        include_examples 'converts to expected schema',
          { email: { default: "example@gitlab.com", type: "string" } }
      end

      context 'with example' do
        let(:entity_class) do
          Class.new(Grape::Entity) do
            expose :email, documentation: { example: 'helloworld@example.com' }
          end
        end

        include_examples 'converts to expected schema',
          { email: { example: "helloworld@example.com", type: "string" } }
      end
    end

    context 'with type conversions' do
      type_conversion_tests = {
        'dateTime' => {
          input: { type: 'dateTime', example: '2012-06-28T10:52:04Z' },
          output: { type: "string", format: "date-time", example: "2012-06-28T10:52:04Z" }
        },
        'String (capital S)' => {
          input: { type: 'String' },
          output: { type: "string" }
        },
        ':int (malformed symbol)' => {
          input: { type: :int },
          output: { type: "integer" }
        },
        'Integer (capital I)' => {
          input: { type: 'Integer' },
          output: { type: "integer" }
        },
        ':hash (malformed symbol)' => {
          input: { type: :hash },
          output: { type: "object" }
        },
        'Hash' => {
          input: { type: 'Hash' },
          output: { type: "object" }
        },
        'text' => {
          input: { type: 'text' },
          output: { type: "string" }
        },
        'date' => {
          input: { type: 'date' },
          output: { type: "string", format: "date" }
        }
      }

      type_conversion_tests.each do |description, config|
        context "with #{description}" do
          let(:entity_class) do
            input_config = config[:input]
            Class.new(Grape::Entity) do
              expose :updated_at, documentation: input_config
            end
          end

          include_examples 'converts to expected schema', { updated_at: config[:output] }
        end
      end

      context 'with multiple possible types' do
        let(:entity_class) do
          Class.new(Grape::Entity) do
            expose :record_identifier, documentation: { type: %w[string integer] }
          end
        end

        include_examples 'converts to expected schema',
          { record_identifier: { oneOf: [{ type: "string" }, { type: "integer" }] } }
      end
    end

    context 'with documentation options' do
      context 'with type and description' do
        let(:entity_class) do
          Class.new(Grape::Entity) do
            expose :id, documentation: { type: 'integer', desc: 'User ID' }
          end
        end

        include_examples 'converts to expected schema',
          { id: { type: "integer", description: "User ID" } }
      end

      context 'with format specification' do
        let(:entity_class) do
          Class.new(Grape::Entity) do
            expose :email, documentation: { type: 'string', format: 'email' }
          end
        end

        include_examples 'converts to expected schema',
          { email: { type: "string", format: "email" } }
      end
    end

    context 'with entity references' do
      shared_examples 'entity reference' do |using_value, expected_ref|
        context "when using #{using_value.class}" do
          let(:entity_class) do
            entity_using = using_value
            Class.new(Grape::Entity) do
              expose :user, using: entity_using
            end
          end

          include_examples 'converts to expected schema',
            { user: { "$ref" => expected_ref } }
        end
      end

      include_examples 'entity reference', 'TestEntities::UserEntity', "#/components/schemas/TestEntitiesUserEntity"
      include_examples 'entity reference', TestEntities::UserEntity, "#/components/schemas/TestEntitiesUserEntity"

      context 'with namespaced entity' do
        let(:entity_class) do
          Class.new(Grape::Entity) do
            expose :user, using: 'Hello::World::Human'
          end
        end

        include_examples 'converts to expected schema',
          { user: { "$ref" => "#/components/schemas/HelloWorldHuman" } }
      end
    end

    context 'with array exposures' do
      shared_examples 'array of items' do |using_value, item_schema|
        let(:entity_class) do
          entity_using = using_value
          Class.new(Grape::Entity) do
            if entity_using
              expose :users, using: entity_using, documentation: { is_array: true }
            else
              expose :users, documentation: { is_array: true, type: 'string' }
            end
          end
        end

        include_examples 'converts to expected schema',
          { users: { type: "array", items: item_schema } }
      end

      context 'with entity string reference' do
        include_examples 'array of items', 'TestEntities::UserEntity',
          { "$ref" => "#/components/schemas/TestEntitiesUserEntity" }
      end

      context 'with entity class reference' do
        include_examples 'array of items', TestEntities::UserEntity,
          { "$ref" => "#/components/schemas/TestEntitiesUserEntity" }
      end

      context 'with primitive type' do
        include_examples 'array of items', nil, { type: "string" }
      end
    end

    context 'with deduplication' do
      let(:entity_class) { TestEntities::UserEntity }
      let(:schema_registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }

      it 'returns same schema object when entity already registered' do
        converter1 = described_class.new(entity_class, schema_registry)
        converter2 = described_class.new(entity_class, schema_registry)

        schema1 = converter1.convert
        schema2 = converter2.convert

        expect(schema1.object_id).to eq(schema2.object_id)
      end

      it 'only registers entity once in schema registry' do
        converter1 = described_class.new(entity_class, schema_registry)
        converter2 = described_class.new(entity_class, schema_registry)

        converter1.convert
        converter2.convert

        expect(schema_registry.schemas.count).to eq(1)
      end
    end
  end
end
