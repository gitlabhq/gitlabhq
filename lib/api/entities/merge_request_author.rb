# frozen_string_literal: true

module API
  module Entities
    class MergeRequestAuthor < UserBasic
      expose :bot?, as: :bot, documentation: { type: 'Boolean', example: false }
    end
  end
end
