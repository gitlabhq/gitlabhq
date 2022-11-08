# frozen_string_literal: true

module API
  module Entities
    class Diff < Grape::Entity
      expose :json_safe_diff, as: :diff, documentation: {
        type: 'string',
        example: '--- a/doc/update/5.4-to-6.0.md\n+++ b/doc/update/5.4-to-6.0.md\n@@ -71,6 +71,8 @@\n...'
      }
      expose :new_path, documentation: { type: 'string', example: 'doc/update/5.4-to-6.0.md' }
      expose :old_path, documentation: { type: 'string', example: 'doc/update/5.4-to-6.0.md' }
      expose :a_mode, documentation: { type: 'string', example: '100755' }
      expose :b_mode, documentation: { type: 'string', example: '100644' }
      expose :new_file?, as: :new_file, documentation: { type: 'boolean' }
      expose :renamed_file?, as: :renamed_file, documentation: { type: 'boolean' }
      expose :deleted_file?, as: :deleted_file, documentation: { type: 'boolean' }
    end
  end
end
