# frozen_string_literal: true

# Finds a migration that still has a spec, for use as a tff mapping example.
#
# Migrations are periodically squashed, so naming one in an example would break
# that example at the next required stop.
class MigrationExampleFinder
  MIGRATION_GLOB = 'db/{migrate,post_migrate}/*.rb'
  SPEC_DIR = 'spec/migrations'

  def initialize(root_path)
    @root_path = root_path
  end

  # Returns [migration_path, spec_path] for the newest migration whose spec uses
  # the given naming form, or nil when no migration is left with such a spec.
  def newest_with_spec(timestamped:)
    migration_paths.each do |path|
      migration = path.delete_prefix(root_path)
      spec = spec_path_for(migration, timestamped: timestamped)

      return [migration, spec] if File.exist?("#{root_path}#{spec}")
    end

    nil
  end

  private

  attr_reader :root_path

  def migration_paths
    # Sort on the basename: the glob spans two directories, so path order would
    # rank every post_migrate ahead of every migrate rather than by timestamp.
    Dir["#{root_path}#{MIGRATION_GLOB}"].sort_by { |path| File.basename(path) }.reverse
  end

  def spec_path_for(migration, timestamped:)
    basename = File.basename(migration, '.rb')
    name = timestamped ? basename : basename.split('_', 2).last

    "#{SPEC_DIR}/#{name}_spec.rb"
  end
end
