# frozen_string_literal: true

module Test
  module References
    class MockWithWritableRootNamespace < MockWithDatabaseRecord
      attr_writer :root_namespace_id
    end
  end
end
