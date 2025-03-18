# frozen_string_literal: true

module Test
  module References
    class MockWithDatabaseRecord < Mock
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
