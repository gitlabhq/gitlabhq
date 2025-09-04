# frozen_string_literal: true

ActiveSupport.on_load(:active_record) do
  if Gitlab.next_rails?
    ActiveRecord::ConnectionAdapters::SchemaCache.prepend(Gitlab::Database::SchemaCacheWithRenamedTable)
  else
    ActiveRecord::ConnectionAdapters::SchemaCache.prepend(Gitlab::Database::SchemaCacheWithRenamedTable71)
  end
end
