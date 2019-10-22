# frozen_string_literal: true

class BackfillSoftwareLicensesSpdxIdentifiers < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CURRENT_LICENSES = {
    'AGPL-1.0' => 'AGPL-1.0',
    'AGPL-3.0' => 'AGPL-3.0',
    'Apache 2.0' => 'Apache-2.0',
    'Artistic-2.0' => 'Artistic-2.0',
    'BSD' => 'BSD-4-Clause',
    'CC0 1.0 Universal' => 'CC0-1.0',
    'CDDL-1.0' => 'CDDL-1.0',
    'CDDL-1.1' => 'CDDL-1.1',
    'EPL-1.0' => 'EPL-1.0',
    'EPL-2.0' => 'EPL-2.0',
    'GPLv2' => 'GPL-2.0',
    'GPLv3' => 'GPL-3.0',
    'ISC' => 'ISC',
    'LGPL' => 'LGPL-3.0-only',
    'LGPL-2.1' => 'LGPL-2.1',
    'MIT' => 'MIT',
    'Mozilla Public License 2.0' => 'MPL-2.0',
    'MS-PL' => 'MS-PL',
    'MS-RL' => 'MS-RL',
    'New BSD' => 'BSD-3-Clause',
    'Python Software Foundation License' => 'Python-2.0',
    'ruby' => 'Ruby',
    'Simplified BSD' => 'BSD-2-Clause',
    'WTFPL' => 'WTFPL',
    'Zlib' => 'Zlib'
  }.freeze

  disable_ddl_transaction!

  # 25 records to be updated on GitLab.com
  def up
    return unless Gitlab.ee?

    say "Expect #{CURRENT_LICENSES.count} updates to the software_licenses table to occur"
    CURRENT_LICENSES.each do |name, spdx_identifier|
      # The following cop is disabled because of https://gitlab.com/gitlab-org/gitlab/issues/33470
      # For more context see https://gitlab.com/gitlab-org/gitlab/merge_requests/17004#note_226264823
      # rubocop:disable Migration/UpdateColumnInBatches
      update_column_in_batches(:software_licenses, :spdx_identifier, spdx_identifier) do |table, query|
        query.where(table[:name].eq(name))
      end
    end
  end

  def down
    return unless Gitlab.ee?

    update_column_in_batches(:software_licenses, :spdx_identifier, nil)
  end
end
