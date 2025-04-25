# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Postgresql::Indexer do
  let(:client) { instance_double(ActiveContext::Databases::Postgresql::Client) }
  let(:options) { {} }
  let(:indexer) { described_class.new(options, client) }
  let(:logger) { instance_double(Logger, warn: nil) }

  before do
    allow(ActiveContext::Config).to receive(:logger).and_return(logger)
  end

  describe '#add_ref' do
    let(:ref) { double }

    before do
      allow(ref).to receive_messages(
        operation: :upsert,
        partition_name: 'issues',
        partition_number: 0,
        identifier: '1',
        ref_version: 123456,
        jsons: [{ title: 'Test Issue', unique_identifier: '1:0' }]
      )
    end

    it 'adds the ref to the refs array' do
      expect { indexer.add_ref(ref) }.to change { indexer.refs.size }.by(1)
      expect(indexer.refs).to include(ref)
    end

    it 'builds an index and delete for the ref' do
      expect { indexer.add_ref(ref) }.to change { indexer.instance_variable_get(:@operations).size }.by(2)

      expect(indexer.instance_variable_get(:@operations).dig(0, :issues).keys).to match_array(:upsert)
      expect(indexer.instance_variable_get(:@operations).dig(1, :issues).keys).to match_array(:delete)
    end

    context 'when operation is update' do
      before do
        allow(ref).to receive(:operation).and_return(:update)
      end

      it 'builds only an index operation for the ref' do
        expect { indexer.add_ref(ref) }.to change { indexer.instance_variable_get(:@operations).size }.by(1)

        expect(indexer.instance_variable_get(:@operations).dig(0, :issues).keys).to match_array(:upsert)
      end
    end

    context 'when operation is delete' do
      before do
        allow(ref).to receive(:operation).and_return(:delete)
      end

      it 'builds only an index operation for the ref' do
        expect { indexer.add_ref(ref) }.to change { indexer.instance_variable_get(:@operations).size }.by(1)

        expect(indexer.instance_variable_get(:@operations).dig(0, :issues).keys).to match_array(:delete)
      end
    end

    it 'returns true when batch size is reached' do
      allow(indexer).to receive(:refs).and_return(Array.new(ActiveContext::Databases::Postgresql::Indexer::BATCH_SIZE))
      expect(indexer.add_ref(ref)).to be true
    end

    it 'returns false when batch size is not reached' do
      expect(indexer.add_ref(ref)).to be false
    end

    it 'raises an error for unsupported operations' do
      allow(ref).to receive(:operation).and_return(:unsupported)
      expect { indexer.add_ref(ref) }.to raise_error(StandardError, /Operation unsupported is not supported/)
    end
  end

  describe '#empty?' do
    it 'returns true when there are no refs' do
      expect(indexer.empty?).to be true
    end

    it 'returns false when there are refs' do
      indexer.instance_variable_set(:@refs, ['ref'])
      expect(indexer.empty?).to be false
    end
  end

  describe '#bulk' do
    it 'calls bulk_process on the client with operations' do
      operations = [{ issues: { upsert: { title: 'Test' } } }]
      indexer.instance_variable_set(:@operations, operations)

      expect(client).to receive(:bulk_process).with(operations)
      indexer.bulk
    end
  end

  describe '#process_bulk_errors' do
    let(:ref1) { double('ref1', unique_identifier: '1:0') }
    let(:ref2) { double('ref2', unique_identifier: '1:0') }
    let(:ref3) { double('ref3', unique_identifier: '2:0') }

    it 'returns unique references based on unique_identifier' do
      expect(ref1).to receive(:unique_identifier).with(nil).and_return('1')
      expect(ref2).to receive(:unique_identifier).with(nil).and_return('1')
      expect(ref3).to receive(:unique_identifier).with(nil).and_return('2')

      result = [ref1, ref2, ref3]
      expect(indexer.process_bulk_errors(result)).to contain_exactly(ref1, ref3)
    end
  end

  describe '#reset' do
    before do
      indexer.instance_variable_set(:@operations, [{ upsert: {} }])
      indexer.instance_variable_set(:@refs, ['ref'])
    end

    it 'resets operations and refs' do
      indexer.reset
      expect(indexer.instance_variable_get(:@operations)).to be_empty
      expect(indexer.refs).to be_empty
    end
  end

  describe '#extract_identifier' do
    it 'extracts the part before the colon' do
      expect(indexer.extract_identifier('123:456')).to eq('123')
    end

    it 'returns the original string if no colon is present' do
      expect(indexer.extract_identifier('123')).to eq('123')
    end
  end

  describe 'operations handling' do
    let(:upsert_ref) { double }
    let(:update_ref) { double }
    let(:delete_ref) { double }

    before do
      allow(upsert_ref).to receive_messages(
        operation: :upsert,
        partition_name: 'issues',
        partition_number: 0,
        identifier: '1',
        ref_version: 123456,
        jsons: [{ title: 'Test Issue', unique_identifier: '1:0' }]
      )

      allow(update_ref).to receive_messages(
        operation: :update,
        partition_name: 'issues',
        partition_number: 0,
        identifier: '2',
        ref_version: 234567,
        jsons: [{ title: 'Test Issue Only', unique_identifier: '2:0' }]
      )

      allow(delete_ref).to receive_messages(
        operation: :delete,
        partition_name: 'issues',
        partition_number: 0,
        identifier: '3'
      )
    end

    context 'with upsert operation' do
      it 'creates upsert and delete operations' do
        indexer.add_ref(upsert_ref)
        operations = indexer.instance_variable_get(:@operations)

        expect(operations.size).to eq(2)

        upsert_op = operations.find { |op| op[:issues][:upsert].present? }
        expect(upsert_op[:issues][:upsert][:title]).to eq('Test Issue')
        expect(upsert_op[:issues][:upsert][:partition_id]).to eq(0)
        expect(upsert_op[:issues][:upsert][:id]).to eq('1:0')

        delete_op = operations.find { |op| op[:issues][:delete].present? }
        expect(delete_op[:issues][:delete][:ref_id]).to eq('1')
        expect(delete_op[:issues][:delete][:ref_version]).to eq(123456)
      end
    end

    context 'with update operation' do
      it 'creates only upsert operations without delete operations' do
        indexer.add_ref(update_ref)
        operations = indexer.instance_variable_get(:@operations)

        expect(operations.size).to eq(1)

        upsert_op = operations.first
        expect(upsert_op[:issues][:upsert][:title]).to eq('Test Issue Only')
        expect(upsert_op[:issues][:upsert][:partition_id]).to eq(0)
        expect(upsert_op[:issues][:upsert][:id]).to eq('2:0')

        delete_op = operations.find { |op| op[:issues][:delete].present? }
        expect(delete_op).to be_nil
      end
    end

    context 'with delete operation' do
      it 'creates only delete operations' do
        indexer.add_ref(delete_ref)
        operations = indexer.instance_variable_get(:@operations)

        expect(operations.size).to eq(1)

        delete_op = operations.first
        expect(delete_op[:issues][:delete][:ref_id]).to eq('3')
        expect(delete_op[:issues][:delete][:ref_version]).to be_nil
      end
    end

    context 'with array values' do
      it 'converts arrays to PostgreSQL array format' do
        allow(upsert_ref).to receive(:jsons).and_return([{
          title: 'Test Issue',
          unique_identifier: '1:0',
          tags: %w[bug urgent]
        }])

        indexer.add_ref(upsert_ref)
        operations = indexer.instance_variable_get(:@operations)

        upsert_op = operations.find { |op| op[:issues][:upsert].present? }
        expect(upsert_op[:issues][:upsert][:tags]).to eq('[bug,urgent]')
      end
    end
  end

  describe '#build_operation' do
    let(:ref) { double }

    before do
      allow(ref).to receive_messages(
        partition_name: 'issues',
        partition_number: 0,
        identifier: '1',
        ref_version: 123456,
        jsons: [{ title: 'Test Issue', unique_identifier: '1:0' }]
      )
    end

    it 'calls build_upsert_operations and build_delete_operation for upsert' do
      allow(ref).to receive(:operation).and_return(:upsert)

      expect(indexer).to receive(:build_upsert_operations).with(ref)
      expect(indexer).to receive(:build_delete_operation).with(ref: ref, include_ref_version: true)

      indexer.send(:build_operation, ref)
    end

    it 'calls only build_upsert_operations for update' do
      allow(ref).to receive(:operation).and_return(:update)

      expect(indexer).to receive(:build_upsert_operations).with(ref)
      expect(indexer).not_to receive(:build_delete_operation)

      indexer.send(:build_operation, ref)
    end

    it 'calls only build_delete_operation for delete' do
      allow(ref).to receive(:operation).and_return(:delete)

      expect(indexer).not_to receive(:build_upsert_operations)
      expect(indexer).to receive(:build_delete_operation).with(ref: ref)

      indexer.send(:build_operation, ref)
    end
  end

  describe '#build_upsert_operations' do
    let(:ref) { double }

    before do
      allow(ref).to receive_messages(
        partition_name: 'issues',
        partition_number: 0,
        jsons: [
          { title: 'Test Issue 1', unique_identifier: '1:0' },
          { title: 'Test Issue 2', unique_identifier: '1:1' }
        ]
      )
    end

    it 'creates upsert operations for each json hash' do
      operations_before = indexer.instance_variable_get(:@operations).dup

      indexer.send(:build_upsert_operations, ref)

      operations_after = indexer.instance_variable_get(:@operations)
      new_operations = operations_after - operations_before

      expect(new_operations.size).to eq(2)

      expect(new_operations[0][:issues][:upsert][:title]).to eq('Test Issue 1')
      expect(new_operations[0][:issues][:upsert][:id]).to eq('1:0')

      expect(new_operations[1][:issues][:upsert][:title]).to eq('Test Issue 2')
      expect(new_operations[1][:issues][:upsert][:id]).to eq('1:1')
    end
  end

  describe '#build_delete_operation' do
    let(:ref) { double }

    before do
      allow(ref).to receive_messages(
        partition_name: 'issues',
        identifier: '1',
        ref_version: 123456
      )
    end

    it 'creates delete operation without ref_version when include_ref_version is false' do
      operation = indexer.send(:build_delete_operation, ref: ref)

      expect(operation[:issues][:delete][:ref_id]).to eq('1')
      expect(operation[:issues][:delete][:ref_version]).to be_nil
    end

    it 'creates delete operation with ref_version when include_ref_version is true' do
      operation = indexer.send(:build_delete_operation, ref: ref, include_ref_version: true)

      expect(operation[:issues][:delete][:ref_id]).to eq('1')
      expect(operation[:issues][:delete][:ref_version]).to eq(123456)
    end
  end

  describe '#build_indexed_json' do
    let(:ref) { double(partition_number: 0) }
    let(:hash) { { title: 'Test Issue', unique_identifier: '1:0', tags: %w[bug urgent] } }

    it 'transforms hash for indexing' do
      result = indexer.send(:build_indexed_json, hash, ref)

      expect(result[:title]).to eq('Test Issue')
      expect(result[:partition_id]).to eq(0)
      expect(result[:id]).to eq('1:0')
      expect(result[:tags]).to eq('[bug,urgent]')
      expect(result[:unique_identifier]).to be_nil
    end
  end

  describe '#convert_pg_array' do
    it 'converts arrays to PostgreSQL array format' do
      expect(indexer.send(:convert_pg_array, %w[one two three])).to eq('[one,two,three]')
    end

    it 'returns non-array values unchanged' do
      expect(indexer.send(:convert_pg_array, 'string')).to eq('string')
      expect(indexer.send(:convert_pg_array, 123)).to eq(123)
      expect(indexer.send(:convert_pg_array, nil)).to be_nil
    end
  end
end
