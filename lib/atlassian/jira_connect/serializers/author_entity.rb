# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class AuthorEntity < Grape::Entity
        include Gitlab::Routing

        expose :name
        expose :email

        with_options(unless: ->(user) { user.is_a?(CommitEntity::CommitAuthor) }) do
          expose :username
          expose :url do |user|
            user_url(user)
          end
          expose :avatar do |user|
            user.avatar_url(only_path: false)
          end
        end
      end
    end
  end
end
