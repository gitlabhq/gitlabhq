# frozen_string_literal: true

module BlobViewer
  class Readme < Base
    include Auxiliary
    include Static

    self.partial_name = 'readme'
    self.file_types = %i[readme]
    self.binary = false

    def visible_to?(current_user, _ref)
      can?(current_user, :read_wiki, project)
    end

    def render_error
      return if project.has_external_wiki? || (project.wiki_enabled? && project.wiki.has_home_page?)

      :no_wiki
    end
  end
end
