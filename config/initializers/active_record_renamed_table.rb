# frozen_string_literal: true

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::SchemaCache.prepend(Gitlab::Database::SchemaCacheWithRenamedTable)
end
