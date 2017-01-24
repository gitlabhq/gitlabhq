# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddEnvironmentSlug < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Adding NOT NULL column environments.slug with dependent data'

  # Used to generate random suffixes for the slug
  NUMBERS = '0'..'9'
  SUFFIX_CHARS = ('a'..'z').to_a + NUMBERS.to_a

  def up
    environments = Arel::Table.new(:environments)

    add_column :environments, :slug, :string
    finder = environments.project(:id, :name)

    connection.exec_query(finder.to_sql).rows.each do |id, name|
      updater = Arel::UpdateManager.new(ActiveRecord::Base).
        table(environments).
        set(environments[:slug] => generate_slug(name)).
        where(environments[:id].eq(id))

      connection.exec_update(updater.to_sql, self.class.name, [])
    end

    change_column_null :environments, :slug, false
  end

  def down
    remove_column :environments, :slug
  end

  # Copy of the Environment#generate_slug implementation
  def generate_slug(name)
    # Lowercase letters and numbers only
    slugified = name.to_s.downcase.gsub(/[^a-z0-9]/, '-')

    # Must start with a letter
    slugified = "env-" + slugified if NUMBERS.cover?(slugified[0])

    # Maximum length: 24 characters (OpenShift limitation)
    slugified = slugified[0..23]

    # Cannot end with a "-" character (Kubernetes label limitation)
    slugified = slugified[0..-2] if slugified[-1] == "-"

    # Add a random suffix, shortening the current string if necessary, if it
    # has been slugified. This ensures uniqueness.
    slugified = slugified[0..16] + "-" + random_suffix if slugified != name

    slugified
  end

  def random_suffix
    (0..5).map { SUFFIX_CHARS.sample }.join
  end
end
