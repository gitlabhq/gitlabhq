require 'spec_helper'

describe PgReplicationSlot, :postgresql do
  if Gitlab::Database.replication_slots_supported?
    describe 'with replication slot support' do
      it '#max_replication_slots' do
        expect(described_class.max_replication_slots).to be >= 0
      end

      skip_examples = PgReplicationSlot.max_replication_slots <= PgReplicationSlot.count
      context 'with enough slots available' do
        before(:all) do
          skip('max_replication_slots too small') if skip_examples

          @current_slot_count =
            ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM pg_replication_slots;")
            .first.fetch('count').to_i
          @current_unused_count =
            ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM pg_replication_slots WHERE active = 'f';")
            .first.fetch('count').to_i

          ActiveRecord::Base.connection.execute("SELECT * FROM pg_create_physical_replication_slot('test_slot');")
        end

        after(:all) do
          unless skip_examples
            ActiveRecord::Base.connection.execute("SELECT pg_drop_replication_slot('test_slot');")
          end
        end

        it '#slots_count' do
          expect(described_class.count).to eq(@current_slot_count + 1)
        end

        it '#unused_slots_count' do
          expect(described_class.unused_slots_count).to eq(@current_unused_count + 1)
        end

        it '#max_retained_wal' do
          expect(PgReplicationSlot.max_retained_wal).not_to be_nil
        end

        it '#slots_retained_bytes' do
          slot = PgReplicationSlot.slots_retained_bytes.find {|x| x['slot_name'] == 'test_slot' }

          expect(slot).not_to be_nil
          expect(slot['retained_bytes']).to be_nil
        end
      end
    end
  end
end
