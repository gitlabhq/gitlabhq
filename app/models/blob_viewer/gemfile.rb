# frozen_string_literal: true

module BlobViewer
  class Gemfile < DependencyManager
    include Static

    self.file_types = %i[gemfile gemfile_lock]

    def manager_name
      'Bundler'
    end

    def manager_url
      'http://bundler.io/'
    end
  end
end
