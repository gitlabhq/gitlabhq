# frozen_string_literal: true

module API
  module Entities
    class Diff < Grape::Entity
      expose :diff, documentation: {
        type: 'String',
        example: '@@ -71,6 +71,8 @@\n...'
      } do |instance, options|
        options[:enable_unidiff] == true ? instance.unidiff : instance.json_safe_diff
      end
      expose :collapsed?, as: :collapsed, documentation: { type: 'Boolean' }
      expose :too_large?, as: :too_large, documentation: { type: 'Boolean' }
      expose :new_path, documentation: { type: 'String', example: 'doc/update/5.4-to-6.0.md' }
      expose :old_path, documentation: { type: 'String', example: 'doc/update/5.4-to-6.0.md' }
      expose :a_mode, documentation: { type: 'String', example: '100755' }
      expose :b_mode, documentation: { type: 'String', example: '100644' }
      expose :new_file?, as: :new_file, documentation: { type: 'Boolean' }
      expose :renamed_file?, as: :renamed_file, documentation: { type: 'Boolean' }
      expose :deleted_file?, as: :deleted_file, documentation: { type: 'Boolean' }
      expose :generated?, as: :generated_file, documentation: { type: 'Boolean' }
    end
  end
end
