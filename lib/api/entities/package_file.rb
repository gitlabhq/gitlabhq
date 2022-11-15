# frozen_string_literal: true

module API
  module Entities
    class PackageFile < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 225 }
      expose :package_id, documentation: { type: 'integer', example: 4 }
      expose :created_at, documentation: { type: 'dateTime', example: '2018-11-07T15:25:52.199Z' }
      expose :file_name, documentation: { type: 'string', example: 'my-app-1.5-20181107.152550-1.jar' }
      expose :size, documentation: { type: 'integer', example: '2421' }
      expose :file_md5, documentation: { type: 'string', example: '58e6a45a629910c6ff99145a688971ac' }
      expose :file_sha1, documentation: { type: 'string', example: 'ebd193463d3915d7e22219f52740056dfd26cbfe' }
      expose :file_sha256, documentation: { type: 'string', example: 'a903393463d3915d7e22219f52740056dfd26cbfeff321b' }
      expose :pipelines, if: ->(package_file) { package_file.pipelines.present? }, using: Package::Pipeline
    end
  end
end
