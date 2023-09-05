# frozen_string_literal: true

module BlobViewer
  class Changelog < Base
    include Auxiliary
    include Static

    self.partial_name = 'changelog'
    self.file_types = %i[changelog]
    self.binary = false

    def render_error
      return if project.repository.tag_count > 0

      :no_tags
    end
  end
end
