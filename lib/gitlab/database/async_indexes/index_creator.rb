# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      class IndexCreator < AsyncIndexes::IndexBase
        STATEMENT_TIMEOUT = 20.hours

        private

        override :preconditions_met?
        def preconditions_met?
          !index_exists?
        end

        override :action_type
        def action_type
          'creation'
        end

        override :around_execution
        def around_execution(&block)
          set_statement_timeout(&block)
        end

        def set_statement_timeout
          connection.execute("SET statement_timeout TO '%ds'" % STATEMENT_TIMEOUT)
          yield
        ensure
          connection.execute('RESET statement_timeout')
        end
      end
    end
  end
end
