# frozen_string_literal: true

module API
  module Entities
    class ChangedPath < Grape::Entity
      expose :status, documentation: { type: 'String', example: 'MODIFIED' } do |changed_path|
        changed_path.status.to_s
      end
      expose :path, documentation: { type: 'String', example: 'app/models/user.rb' }
      expose :old_path, documentation: { type: 'String', example: 'app/models/user.rb' }
      expose :old_mode, documentation: { type: 'String', example: '100644' }
      expose :new_mode, documentation: { type: 'String', example: '100644' }
    end
  end
end
