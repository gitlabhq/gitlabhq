# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# This migration depends on code external to it. For example, it relies on
# updating a namespace to also rename directories (uploads, GitLab pages, etc).
# The alternative is to copy hundreds of lines of code into this migration,
# adjust them where needed, etc; something which doesn't work well at all.
class TurnNestedGroupsIntoRegularGroupsForMysql < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def run_migration?
    Gitlab::Database.mysql?
  end

  def up
    return unless run_migration?

    # For all sub-groups we need to give the right people access. We do this as
    # follows:
    #
    # 1. Get all the ancestors for the current namespace
    # 2. Get all the members of these namespaces, along with their higher access
    #    level
    # 3. Give these members access to the current namespace
    Namespace.unscoped.where('parent_id IS NOT NULL').find_each do |namespace|
      rows = []
      existing = namespace.members.pluck(:user_id)

      all_members_for(namespace).each do |member|
        next if existing.include?(member[:user_id])

        rows << {
          access_level: member[:access_level],
          source_id: namespace.id,
          source_type: 'Namespace',
          user_id: member[:user_id],
          notification_level: 3, # global
          type: 'GroupMember',
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      bulk_insert_members(rows)

      namespace.update!(parent_id: nil, path: new_path_for(namespace))
    end
  end

  def down
    # There is no way to go back from regular groups to nested groups.
  end

  # Generates a new (unique) path for a namespace.
  def new_path_for(namespace)
    counter = 1
    base = namespace.full_path.tr('/', '-')
    new_path = base

    while Namespace.unscoped.where(path: new_path).exists?
      new_path = base + "-#{counter}"
      counter += 1
    end

    new_path
  end

  # Returns an Array containing all the ancestors of the current namespace.
  #
  # This method is not particularly efficient, but it's probably still faster
  # than using the "routes" table. Most importantly of all, it _only_ depends
  # on the namespaces table and the "parent_id" column.
  def ancestors_for(namespace)
    ancestors = []
    current = namespace

    while current&.parent_id
      # We're using find_by(id: ...) here to deal with cases where the
      # parent_id may point to a missing row.
      current = Namespace.unscoped.select([:id, :parent_id])
        .find_by(id: current.parent_id)

      ancestors << current.id if current
    end

    ancestors
  end

  # Returns a relation containing all the members that have access to any of
  # the current namespace's parent namespaces.
  def all_members_for(namespace)
    Member
      .unscoped
      .select(['user_id', 'MAX(access_level) AS access_level'])
      .where(source_type: 'Namespace', source_id: ancestors_for(namespace))
      .group(:user_id)
  end

  def bulk_insert_members(rows)
    return if rows.empty?

    keys = rows.first.keys

    tuples = rows.map do |row|
      row.map { |(_, value)| connection.quote(value) }
    end

    execute <<-EOF.strip_heredoc
    INSERT INTO members (#{keys.join(', ')})
    VALUES #{tuples.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}
    EOF
  end
end
