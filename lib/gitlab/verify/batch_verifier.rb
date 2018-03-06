module Gitlab
  module Verify
    class BatchVerifier
      attr_reader :batch_size, :start, :finish

      def initialize(batch_size:, start: nil, finish: nil)
        @batch_size = batch_size
        @start = start
        @finish = finish
      end

      # Yields a Range of IDs and a Hash of failed verifications (object => error)
      def run_batches(&blk)
        relation.in_batches(of: batch_size, start: start, finish: finish) do |relation| # rubocop: disable Cop/InBatches
          range = relation.first.id..relation.last.id
          failures = run_batch(relation)

          yield(range, failures)
        end
      end

      def name
        raise NotImplementedError.new
      end

      def describe(_object)
        raise NotImplementedError.new
      end

      private

      def run_batch(relation)
        relation.map { |upload| verify(upload) }.compact.to_h
      end

      def verify(object)
        expected = expected_checksum(object)
        actual = actual_checksum(object)

        raise 'Checksum missing' unless expected.present?
        raise 'Checksum mismatch' unless expected == actual

        nil
      rescue => err
        [object, err]
      end

      # This should return an ActiveRecord::Relation suitable for calling #in_batches on
      def relation
        raise NotImplementedError.new
      end

      # The checksum we expect the object to have
      def expected_checksum(_object)
        raise NotImplementedError.new
      end

      # The freshly-recalculated checksum of the object
      def actual_checksum(_object)
        raise NotImplementedError.new
      end
    end
  end
end
