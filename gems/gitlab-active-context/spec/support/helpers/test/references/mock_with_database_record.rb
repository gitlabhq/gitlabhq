# frozen_string_literal: true

module Test
  module References
    class MockWithDatabaseRecord < Mock
      def self.model_klass
        Class.new do
          def self.find_by(id:)
            { id: id }
          end
        end
      end

      def model_klass
        self.class.model_klass
      end

      def database_record
        @database_record ||= model_klass.find_by(id: identifier)
      end

      attr_writer :database_record

      def operation
        database_record ? :upsert : :delete
      end
    end
  end
end
