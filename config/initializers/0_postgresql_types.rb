# frozen_string_literal: true

# As discussed in https://github.com/rails/rails/issues/40687, this
# patch registers a few types to silence warnings when Rails comes
# across some PostgreSQL types it does not recognize.
module PostgreSQLAdapterCustomTypes
  def initialize_type_map(m = type_map) # rubocop:disable Naming/MethodParameterName
    m.register_type('xid', ActiveRecord::Type::Integer.new(limit: 8))
    m.register_type('pg_node_tree', ActiveRecord::Type::String.new)
    m.register_type('_aclitem', ActiveRecord::Type::String.new)
    m.register_type('pg_lsn', ActiveRecord::Type::String.new)

    super
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterCustomTypes)
