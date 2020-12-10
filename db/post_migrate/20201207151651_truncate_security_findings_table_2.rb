# frozen_string_literal: true

require_relative Rails.root.join('db', 'post_migrate', '20201102152945_truncate_security_findings_table.rb')

# This is the second time we are truncating this table
# so the migration class name has choosen like this for this reason.
class TruncateSecurityFindingsTable2 < TruncateSecurityFindingsTable; end
