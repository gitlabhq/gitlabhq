module Gitlab
  module Entities
    class User < Grape::Entity
      expose :id, :email, :name, :bio, :skype, :linkedin, :twitter,
             :dark_scheme, :theme_id, :blocked, :created_at
    end
  end
end
