# frozen_string_literal: true

module Evidences
  class PackageEntity < Grape::Entity
    expose :id
    expose :name
    expose :version
    expose :package_type
    expose :created_at
  end
end
