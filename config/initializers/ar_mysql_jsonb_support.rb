# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_mysql_adapter'
require 'active_record/connection_adapters/mysql/schema_definitions'

# MySQL (5.6) and MariaDB (10.1) are currently supported versions within GitLab,
# Since they do not support native `json` datatype we force to emulate it as `text`

if Gitlab::Database.mysql?
  module ActiveRecord
    module ConnectionAdapters
      class AbstractMysqlAdapter
        JSON_DATASIZE = 1.megabyte

        NATIVE_DATABASE_TYPES.merge!(
          json: { name: "text", limit: JSON_DATASIZE },
          jsonb: { name: "text", limit: JSON_DATASIZE }
        )
      end

      module MySQL
        module ColumnMethods
          # We add `jsonb` helper, as `json` is already defined for `MySQL` since Rails 5
          def jsonb(*args, **options)
            args.each { |name| column(name, :json, options) }
          end
        end
      end
    end
  end
end
