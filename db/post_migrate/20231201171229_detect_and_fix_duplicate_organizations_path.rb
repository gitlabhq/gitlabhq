# frozen_string_literal: true

class DetectAndFixDuplicateOrganizationsPath < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.7'

  module Organizations
    class Organization < Gitlab::Database::Migration[2.2]::MigrationRecord
    end
  end

  def up
    duplicate_paths = Organizations::Organization.group("lower(path)").having("count(path) > 1").count.keys
    duplicate_paths.each do |dup_path|
      # the first one found is the 'winner' here and so we'll drop it an only focus on others
      Organizations::Organization.where('lower(path) = ?', dup_path).order(id: :asc).drop(1).each do |dup_path_record|
        dup_path_record.update!(path: clean_path(dup_path_record.path))
      end
    end
  end

  def down
    # no-op no reversal required here.
  end

  private

  def clean_path(path)
    slug = Gitlab::Slug::Path.new(path).generate
    path = Namespaces::RandomizedSuffixPath.new(slug)
    Gitlab::Utils::Uniquify.new.string(path) do |s|
      Organizations::Organization.find_by('lower(path) = :value', value: s.downcase)
    end
  end
end
