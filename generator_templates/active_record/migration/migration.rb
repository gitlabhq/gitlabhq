# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class <%= migration_class_name %> < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  # DOWNTIME_REASON = ''

  # When using the methods "add_concurrent_index", "remove_concurrent_index" or
  # "add_column_with_default" you must disable the use of transactions
  # as these methods can not run in an existing transaction.
  # When using "add_concurrent_index" or "remove_concurrent_index" methods make sure
  # that either of them is the _only_ method called in the migration,
  # any other changes should go in a separate migration.
  # This ensures that upon failure _only_ the index creation or removing fails
  # and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  # disable_ddl_transaction!

<%- if migration_action == 'add' -%>
  def change
<% attributes.each do |attribute| -%>
  <%- if attribute.reference? -%>
    add_reference :<%= table_name %>, :<%= attribute.name %><%= attribute.inject_options %>
  <%- else -%>
    add_column :<%= table_name %>, :<%= attribute.name %>, :<%= attribute.type %><%= attribute.inject_options %>
    <%- if attribute.has_index? -%>
    add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
    <%- end -%>
  <%- end -%>
<%- end -%>
  end
<%- elsif migration_action == 'join' -%>
  def change
    create_join_table :<%= join_tables.first %>, :<%= join_tables.second %> do |t|
    <%- attributes.each do |attribute| -%>
      <%= '# ' unless attribute.has_index? -%>t.index <%= attribute.index_name %><%= attribute.inject_index_options %>
    <%- end -%>
    end
  end
<%- else -%>
  def change
<% attributes.each do |attribute| -%>
<%- if migration_action -%>
  <%- if attribute.reference? -%>
    remove_reference :<%= table_name %>, :<%= attribute.name %><%= attribute.inject_options %>
  <%- else -%>
    <%- if attribute.has_index? -%>
    remove_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
    <%- end -%>
    remove_column :<%= table_name %>, :<%= attribute.name %>, :<%= attribute.type %><%= attribute.inject_options %>
  <%- end -%>
<%- end -%>
<%- end -%>
  end
<%- end -%>
end
