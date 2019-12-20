# frozen_string_literal: true

class AddUniqueConstraintToSoftwareLicenses < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false
  NEW_INDEX = 'index_software_licenses_on_unique_name'
  OLD_INDEX = 'index_software_licenses_on_name'

  disable_ddl_transaction!

  # 12 software licenses will be removed on GitLab.com
  # 0 software license policies will be updated on GitLab.com
  def up(attempts: 100)
    remove_redundant_software_licenses!

    add_concurrent_index :software_licenses, :name, unique: true, name: NEW_INDEX
    remove_concurrent_index :software_licenses, :name, name: OLD_INDEX
  rescue ActiveRecord::RecordNotUnique
    retry if (attempts -= 1) > 0

    raise StandardError, <<~EOS
      Failed to add an unique index to software_licenses, despite retrying the
      migration 100 times.

      See https://gitlab.com/gitlab-org/gitlab/merge_requests/19840.
    EOS
  end

  def down
    remove_concurrent_index :software_licenses, :name, unique: true, name: NEW_INDEX
    add_concurrent_index :software_licenses, :name, name: OLD_INDEX
  end

  private

  def remove_redundant_software_licenses!
    redundant_software_licenses = execute <<~SQL
      SELECT min(id) id, name
      FROM software_licenses
      WHERE name IN (select name from software_licenses group by name having count(name) > 1)
      GROUP BY name
    SQL
    say "Detected #{redundant_software_licenses.count} duplicates."

    redundant_software_licenses.each_row do |id, name|
      say_with_time("Reassigning policies that reference software license #{name}.") do
        duplicates = software_licenses.where.not(id: id).where(name: name)

        software_license_policies
          .where(software_license_id: duplicates)
          .update_all(software_license_id: id)

        duplicates.delete_all
      end
    end
  end

  def table(name)
    Class.new(ActiveRecord::Base) { self.table_name = name }
  end

  def software_licenses
    @software_licenses ||= table(:software_licenses)
  end

  def software_license_policies
    @software_license_policies ||= table(:software_license_policies)
  end
end
