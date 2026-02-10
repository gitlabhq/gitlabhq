# frozen_string_literal: true

module Test
  module Collections
    class Mock
      include ::ActiveContext::Concerns::Collection

      def self.collection_name
        'test_mock_collection'
      end

      def self.queue
        'test_queue'
      end

      def self.reference_klass
        Test::References::Mock
      end

      def self.routing(object)
        object.id
      end

      def self.embedding_model_selector
        Test::MockEmbeddingModelSelector
      end
    end
  end
end
