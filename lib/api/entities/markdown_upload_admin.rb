# frozen_string_literal: true

module API
  module Entities
    class MarkdownUploadAdmin < Grape::Entity
      expose :id
      expose :size
      expose :filename
      expose :created_at
      expose :uploaded_by_user, as: :uploaded_by, using: Entities::UserSafe
    end
  end
end
