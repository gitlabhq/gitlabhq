# frozen_string_literal: true

module API
  module Entities
    class PackageFile < Grape::Entity
      expose :id, :package_id, :created_at
      expose :file_name, :size
      expose :file_md5, :file_sha1
    end
  end
end
