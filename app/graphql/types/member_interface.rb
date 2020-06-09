# frozen_string_literal: true

module Types
  module MemberInterface
    include BaseInterface

    field :access_level, Types::AccessLevelType, null: true,
          description: 'GitLab::Access level'

    field :created_by, Types::UserType, null: true,
          description: 'User that authorized membership'

    field :created_at, Types::TimeType, null: true,
          description: 'Date and time the membership was created'

    field :updated_at, Types::TimeType, null: true,
          description: 'Date and time the membership was last updated'

    field :expires_at, Types::TimeType, null: true,
          description: 'Date and time the membership expires'
  end
end
