# frozen_string_literal: true

module BlobViewer
  class YarnLock < DependencyManager
    include Static

    self.file_types = %i[yarn_lock]

    def manager_name
      'Yarn'
    end

    def manager_url
      'https://yarnpkg.com/'
    end
  end
end
