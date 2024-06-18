# frozen_string_literal: true

module API
  module Entities
    class Commit < Grape::Entity
      expose :id, documentation: { type: 'string', example: '2695effb5807a22ff3d138d593fd856244e155e7' }
      expose :short_id, documentation: { type: 'string', example: '2695effb' }
      expose :created_at, documentation: { type: 'dateTime', example: '2017-07-26T11:08:53.000+02:00' }
      expose :parent_ids,
        documentation: { type: 'string', is_array: true, example: '2a4b78934375d7f53875269ffd4f45fd83a84ebe' }
      expose :full_title, as: :title, documentation: { type: 'string', example: 'Initial commit' }
      expose :safe_message, as: :message, documentation: { type: 'string', example: 'Initial commit' }
      expose :author_name, documentation: { type: 'string', example: 'John Smith' }
      expose :author_email, documentation: { type: 'string', example: 'john@example.com' }
      expose :authored_date, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :committer_name, documentation: { type: 'string', example: 'Jack Smith' }
      expose :committer_email, documentation: { type: 'string', example: 'jack@example.com' }
      expose :committed_date, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :trailers, documentation: { type: 'object', example: '{ "Merged-By": "Jane Doe janedoe@gitlab.com" }' }
      expose :extended_trailers, documentation: {
        type: 'object',
        example: '{ "Signed-off-by": ["John Doe <johndoe@gitlab.com>", "Jane Doe <janedoe@gitlab.com>"] }'
      }

      expose :web_url,
        documentation: {
          type: 'string',
          example: 'https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746'
        } do |commit, _options|
        c = commit
        c = c.__subject__ if c.is_a?(Gitlab::View::Presenter::Base)
        Gitlab::UrlBuilder.build(c)
      end
    end
  end
end
