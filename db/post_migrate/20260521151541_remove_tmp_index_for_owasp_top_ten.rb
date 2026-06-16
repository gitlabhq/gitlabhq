# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveTmpIndexForOwaspTopTen < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  INDEX_NAME = 'tmp_index_vuln_reads_on_id_where_owasp_2021'

  def up
    remove_concurrent_index_by_name(:vulnerability_reads, INDEX_NAME)
  end

  def down
    add_concurrent_index(
      :vulnerability_reads,
      :id,
      where: 'owasp_top_10 IN (11, 12, 13, 14, 15, 16, 17, 18, 19, 20)',
      name: INDEX_NAME
    )
  end
end
