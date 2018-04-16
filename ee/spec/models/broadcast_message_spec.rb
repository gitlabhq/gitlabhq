require 'spec_helper'

describe BroadcastMessage do
  subject { build(:broadcast_message) }

  describe '.current', :use_clean_rails_memory_store_caching do
    context 'without Geo' do
      it 'caches the output for a long time' do
        expect(Gitlab::Geo).to receive(:enabled?).and_return(false).exactly(2).times

        create(:broadcast_message)

        expect(described_class).to receive(:where).and_call_original.once

        described_class.current

        Timecop.travel(1.year) do
          described_class.current
        end
      end
    end

    context 'with Geo' do
      context 'on the primary' do
        it 'caches the output for a long time' do
          expect(Gitlab::Geo).to receive(:secondary?).and_return(false).exactly(2).times

          create(:broadcast_message)

          expect(described_class).to receive(:where).and_call_original.once

          described_class.current

          Timecop.travel(1.year) do
            described_class.current
          end
        end
      end

      context 'on a secondary' do
        it 'caches the output for a short time' do
          expect(Gitlab::Geo).to receive(:secondary?).and_return(true).exactly(3).times

          create(:broadcast_message)

          expect(described_class).to receive(:where).and_call_original.once

          described_class.current

          Timecop.travel(20.seconds) do
            described_class.current
          end

          expect(described_class).to receive(:where).and_call_original.once

          Timecop.travel(40.seconds) do
            described_class.current
          end
        end
      end
    end
  end
end
