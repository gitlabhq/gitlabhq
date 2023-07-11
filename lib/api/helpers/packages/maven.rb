# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Maven
        extend Grape::API::Helpers

        params :path_and_file_name do
          requires :path,
            type: String,
            desc: 'Package path',
            documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT' }
          requires :file_name,
            type: String,
            desc: 'Package file name',
            documentation: { example: 'mypkg-1.0-SNAPSHOT.jar' }
        end
      end
    end
  end
end
