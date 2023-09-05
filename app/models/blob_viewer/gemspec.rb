# frozen_string_literal: true

module BlobViewer
  class Gemspec < DependencyManager
    include ServerSide

    self.file_types = %i[gemspec]

    def manager_name
      'RubyGems'
    end

    def manager_url
      'https://rubygems.org/'
    end

    def package_type
      'gem'
    end

    def package_name
      @package_name ||= package_name_from_method_call('name')
    end

    def package_url
      "https://rubygems.org/gems/#{package_name}"
    end
  end
end
