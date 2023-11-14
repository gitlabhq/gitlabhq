# frozen_string_literal: true

ActiveSupport.on_load(:active_record) do
  if Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new('7.1')
    ActiveRecord::ConnectionAdapters::SchemaCache.prepend(Gitlab::Database::SchemaCacheWithRenamedTable)
  else
    ActiveRecord::ConnectionAdapters::SchemaCache.prepend(Gitlab::Database::SchemaCacheWithRenamedTableLegacy)
  end
end
