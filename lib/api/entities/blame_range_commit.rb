# frozen_string_literal: true

module API
  module Entities
    class BlameRangeCommit < Grape::Entity
      expose :id, documentation: { type: 'String', example: '2695effb5807a22ff3d138d593fd856244e155e7' }
      expose :parent_ids,
        documentation: { type: 'String', is_array: true, example: ['2a4b78934375d7f53875269ffd4f45fd83a84ebe'] }
      expose :message, documentation: { type: 'String', example: 'Initial commit' }
      expose :authored_date, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :author_name, documentation: { type: 'String', example: 'John Smith' }
      expose :author_email, documentation: { type: 'String', example: 'john@example.com' }
      expose :committed_date, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :committer_name, documentation: { type: 'String', example: 'Jack Smith' }
      expose :committer_email, documentation: { type: 'String', example: 'jack@example.com' }
    end
  end
end
