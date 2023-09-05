# frozen_string_literal: true

module ActivityPub
  class UserEntity < Grape::Entity
    include RequestAwareEntity

    expose :id do |user|
      user_url(user)
    end

    expose :type do |*|
      'Person'
    end

    expose :name
    expose :username, as: :preferredUsername

    expose :url do |user|
      user_url(user)
    end
  end
end
