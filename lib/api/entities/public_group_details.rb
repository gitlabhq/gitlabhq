# frozen_string_literal: true

module API
  module Entities
    class PublicGroupDetails < BasicGroupDetails
      expose :avatar_url,
        documentation: { type: 'String',
                         example: 'http://gitlab.example.com/uploads/group/avatar/1/avatar.png' } do |group, options|
        group.avatar_url(only_path: false)
      end
      expose :full_name, documentation: { type: 'String', example: 'Foobar Group' }
      expose :full_path, documentation: { type: 'String', example: 'foo-bar' }
    end
  end
end
