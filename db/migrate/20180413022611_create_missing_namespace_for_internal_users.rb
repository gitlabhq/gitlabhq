class CreateMissingNamespaceForInternalUsers < ActiveRecord::Migration
  DOWNTIME = false

  def up
    connection.exec_query(users_query.to_sql).rows.each do |id, username|
      create_namespace(id, username)
      # When testing locally I've noticed that these internal users are missing
      # the notification email, for more details visit the below link:
      # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18357#note_68327560
      set_notification_email(id)
    end
  end

  def down
    # no-op
  end

  private

  def users
    @users ||= Arel::Table.new(:users)
  end

  def namespaces
    @namespaces ||= Arel::Table.new(:namespaces)
  end

  def users_query
    condition = users[:ghost].eq(true)

    if column_exists?(:users, :support_bot)
      condition = condition.or(users[:support_bot].eq(true))
    end

    users.join(namespaces, Arel::Nodes::OuterJoin)
      .on(namespaces[:type].eq(nil).and(namespaces[:owner_id].eq(users[:id])))
      .where(namespaces[:owner_id].eq(nil))
      .where(condition)
      .project(users[:id], users[:username])
  end

  def create_namespace(user_id, username)
    path = Uniquify.new.string(username) do |str|
      query = "SELECT id FROM namespaces WHERE parent_id IS NULL AND path='#{str}' LIMIT 1"
      connection.exec_query(query).present?
    end

    insert_query = "INSERT INTO namespaces(owner_id, path, name) VALUES(#{user_id}, '#{path}', '#{path}')"
    namespace_id = connection.insert_sql(insert_query)

    create_route(namespace_id)
  end

  def create_route(namespace_id)
    return unless namespace_id

    row = connection.exec_query("SELECT id, path FROM namespaces WHERE id=#{namespace_id}").first
    id, path = row.values_at('id', 'path')

    execute("INSERT INTO routes(source_id, source_type, path, name) VALUES(#{id}, 'Namespace', '#{path}', '#{path}')")
  end

  def set_notification_email(user_id)
    execute "UPDATE users SET notification_email = email WHERE notification_email IS NULL AND id = #{user_id}"
  end
end
