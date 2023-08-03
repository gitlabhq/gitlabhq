# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Sources
        module ConnectionAdapters
          class Base
            def initialize(connection)
              @connection = connection
            end

            def current_schema
              raise NotImplementedError, "#{self.class} does not implement #{__method__}"
            end

            def select_rows(sql, schemas = [])
              raise NotImplementedError, "#{self.class} does not implement #{__method__}"
            end

            def exec_query(sql, schemas = [])
              raise NotImplementedError, "#{self.class} does not implement #{__method__}"
            end

            private

            attr_reader :connection
          end
        end
      end
    end
  end
end
