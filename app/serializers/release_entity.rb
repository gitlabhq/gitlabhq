# frozen_string_literal: true

class ReleaseEntity < Grape::Entity
  expose :id
  expose :tag # see https://gitlab.com/gitlab-org/gitlab/-/issues/36338
end
