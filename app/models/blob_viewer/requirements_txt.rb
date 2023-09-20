# frozen_string_literal: true

module BlobViewer
  class RequirementsTxt < DependencyManager
    include Static

    self.file_types = %i[requirements_txt]

    def manager_name
      'pip'
    end

    def manager_url
      'https://pip.pypa.io/'
    end
  end
end
