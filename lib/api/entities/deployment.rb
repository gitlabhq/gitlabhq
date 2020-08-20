# frozen_string_literal: true

module API
  module Entities
    class Deployment < Grape::Entity
      expose :id, :iid, :ref, :sha, :created_at, :updated_at
      expose :user,        using: Entities::UserBasic
      expose :environment, using: Entities::EnvironmentBasic
      expose :deployable,  using: Entities::Ci::Job
      expose :status
    end
  end
end
