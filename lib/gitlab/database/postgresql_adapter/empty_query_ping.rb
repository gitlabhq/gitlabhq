# frozen_string_literal: true

# This patch will be included in the next Rails release: https://github.com/rails/rails/pull/42368
raise 'This patch can be removed' if Rails::VERSION::MAJOR > 6

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
