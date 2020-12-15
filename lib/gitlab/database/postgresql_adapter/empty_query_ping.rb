# frozen_string_literal: true

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module Gitlab
  module Database
    module PostgresqlAdapter
      module EmptyQueryPing
        # ActiveRecord uses `SELECT 1` to check if the connection is alive
        # We patch this here to use an empty query instead, which is a bit faster
        def active?
          @lock.synchronize do
            @connection.query ';'
          end
          true
        rescue PG::Error
          false
        end
      end
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
