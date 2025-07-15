# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Rails/SquishedSQLHeredocs -- This gem does not depend on Rails
RSpec.describe Gitlab::Schema::Validation::Sources::SequenceStructureSqlParser, feature_category: :database do
  let(:default_schema_name) { 'public' }

  subject(:parser) { described_class.new(parsed_structure, default_schema_name) }

  describe '#execute' do
    let(:parsed_structure) { PgQuery.parse(sql) }

    context 'with CREATE SEQUENCE statements' do
      where(:sql, :expected_sequences) do
        [
          [
            'CREATE SEQUENCE public.web_hook_logs_id_seq;',
            { 'public.web_hook_logs_id_seq' => { sequence_name: 'web_hook_logs_id_seq', schema_name: 'public' } }
          ],
          [
            'CREATE SEQUENCE web_hook_logs_id_seq;',
            { 'public.web_hook_logs_id_seq' => { sequence_name: 'web_hook_logs_id_seq', schema_name: 'public' } }
          ],
          [
            'CREATE SEQUENCE custom_schema.test_seq;',
            { 'custom_schema.test_seq' => { sequence_name: 'test_seq', schema_name: 'custom_schema' } }
          ]
        ]
      end

      with_them do
        it 'creates sequences with correct attributes' do
          result = parser.execute

          expected_sequences.each do |full_name, expected_attrs|
            expect(result).to have_key(full_name)
            sequence = result[full_name]
            expect(sequence).to be_a(Gitlab::Schema::Validation::Adapters::SequenceStructureSqlAdapter)
            expect(sequence.sequence_name).to eq(expected_attrs[:sequence_name])
            expect(sequence.schema_name).to eq(expected_attrs[:schema_name])
          end
        end
      end
    end

    context 'with ALTER SEQUENCE OWNED BY statements' do
      let(:sql) do
        <<~SQL
          CREATE SEQUENCE public.ai_code_suggestion_events_id_seq;
          ALTER SEQUENCE public.ai_code_suggestion_events_id_seq OWNED BY ai_code_suggestion_events.id;
        SQL
      end

      it 'sets ownership information' do
        result = parser.execute
        sequence = result['public.ai_code_suggestion_events_id_seq']

        expect(sequence.sequence_name).to eq('ai_code_suggestion_events_id_seq')
        expect(sequence.schema_name).to eq('public')
        expect(sequence.owner_table).to eq('ai_code_suggestion_events')
        expect(sequence.owner_column).to eq('id')
        expect(sequence.owner_schema).to eq('public')
      end
    end

    context 'with ALTER SEQUENCE OWNED BY with schema.table.column format' do
      let(:sql) do
        <<~SQL
          CREATE SEQUENCE public.test_seq;
          ALTER SEQUENCE public.test_seq OWNED BY custom_schema.test_table.test_column;
        SQL
      end

      it 'sets ownership information with custom schema' do
        result = parser.execute
        sequence = result['public.test_seq']

        expect(sequence.owner_table).to eq('test_table')
        expect(sequence.owner_column).to eq('test_column')
        expect(sequence.owner_schema).to eq('custom_schema')
      end
    end

    context 'with ALTER TABLE SET DEFAULT nextval statements' do
      # rubocop:disable Layout/LineLength -- Long SQL statements are unavoidable
      where(:sql, :parsed_sequence_name, :expected_sequence_name, :expected_owner_table, :expected_owner_column) do
        [
          [
            "CREATE SEQUENCE public.web_hook_logs_id_seq;
              ALTER TABLE ONLY public.web_hook_logs ALTER COLUMN id SET DEFAULT nextval('web_hook_logs_id_seq'::regclass);",
            'public.web_hook_logs_id_seq',
            'web_hook_logs_id_seq',
            'web_hook_logs',
            'id'
          ],
          [
            "CREATE SEQUENCE public.issues_id_seq;
              ALTER TABLE public.issues ALTER COLUMN id SET DEFAULT nextval('public.issues_id_seq'::regclass);",
            'public.issues_id_seq',
            'issues_id_seq',
            'issues',
            'id'
          ],
          [
            "CREATE SEQUENCE public.test_seq;
              ALTER TABLE custom_schema.test_table ALTER COLUMN test_id SET DEFAULT nextval('test_seq'::regclass);",
            'public.test_seq',
            'test_seq',
            'test_table',
            'test_id'
          ]
        ]
        # rubocop:enable Layout/LineLength
      end

      with_them do
        it 'extracts sequence ownership from ALTER TABLE statements' do
          result = parser.execute
          sequence = result[parsed_sequence_name]

          expect(sequence).to be_a(Gitlab::Schema::Validation::Adapters::SequenceStructureSqlAdapter)
          expect(sequence.sequence_name).to eq(expected_sequence_name)
          expect(sequence.owner_table).to eq(expected_owner_table)
          expect(sequence.owner_column).to eq(expected_owner_column)
        end
      end
    end

    context 'with combined CREATE and ALTER statements' do
      let(:sql) do
        <<~SQL
          CREATE SEQUENCE public.web_hook_logs_id_seq;
          ALTER TABLE ONLY public.web_hook_logs ALTER COLUMN id SET DEFAULT nextval('web_hook_logs_id_seq'::regclass);
          ALTER SEQUENCE public.web_hook_logs_id_seq OWNED BY web_hook_logs.id;
        SQL
      end

      it 'processes all statements and merges information' do
        result = parser.execute
        sequence = result['public.web_hook_logs_id_seq']

        expect(sequence.sequence_name).to eq('web_hook_logs_id_seq')
        expect(sequence.schema_name).to eq('public')
        expect(sequence.owner_table).to eq('web_hook_logs')
        expect(sequence.owner_column).to eq('id')
        expect(sequence.owner_schema).to eq('public')
      end
    end

    context 'with multiple sequences' do
      let(:sql) do
        <<~SQL
          CREATE SEQUENCE public.users_id_seq;
          CREATE SEQUENCE public.projects_id_seq;
          ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);
          ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);
        SQL
      end

      it 'processes multiple sequences correctly' do
        result = parser.execute

        expect(result).to have_key('public.users_id_seq')
        expect(result).to have_key('public.projects_id_seq')

        users_seq = result['public.users_id_seq']
        projects_seq = result['public.projects_id_seq']

        expect(users_seq.owner_table).to eq('users')
        expect(projects_seq.owner_table).to eq('projects')
      end
    end

    context 'with ALTER SEQUENCE on non-existent sequence' do
      let(:sql) do
        <<~SQL
          ALTER SEQUENCE public.non_existent_seq OWNED BY test_table.id;
        SQL
      end

      it 'warns about missing sequence' do
        expect(parser).to receive(:warn).with(
          'Could not find sequence public.non_existent_seq for ALTER SEQUENCE command')
        parser.execute
      end
    end

    context 'with non-sequence statements' do
      let(:sql) do
        <<~SQL
          CREATE TABLE public.test_table (id integer);
          CREATE INDEX idx_test ON public.test_table (id);
          ALTER TABLE public.test_table ADD COLUMN name varchar(255);
        SQL
      end

      it 'ignores non-sequence statements' do
        result = parser.execute
        expect(result).to be_empty
      end
    end

    context 'with empty SQL' do
      let(:sql) { '' }

      it 'retuSQL.squishSQL.squishrns empty hash' do
        result = parser.execute
        expect(result).to eq({})
      end
    end

    context 'with complex nextval expressions' do
      let(:sql) do
        <<~SQL
          CREATE SEQUENCE public.test_seq;
          ALTER TABLE public.test_table ALTER COLUMN id SET DEFAULT nextval(('test_seq'::text)::regclass);
        SQL
      end

      it 'extracts sequence name from complex expressions' do
        result = parser.execute
        sequence = result['public.test_seq']

        expect(sequence.sequence_name).to eq('test_seq')
        expect(sequence.owner_table).to eq('test_table')
        expect(sequence.owner_column).to eq('id')
      end
    end
  end

  describe 'default schema handling' do
    context 'with custom default schema' do
      let(:default_schema_name) { 'custom_default' }
      let(:sql) { 'CREATE SEQUENCE test_seq;' }
      let(:parsed_structure) { PgQuery.parse(sql) }

      it 'uses custom default schema' do
        result = parser.execute
        sequence = result['custom_default.test_seq']

        expect(sequence.schema_name).to eq('custom_default')
      end
    end
  end
end
# rubocop:enable Rails/SquishedSQLHeredocs
