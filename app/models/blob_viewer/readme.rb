module BlobViewer
  class Readme < Base
    include Auxiliary
    include Static

    self.partial_name = 'readme'
    self.file_types = %i(readme)
    self.binary = false

    def visible_to?(current_user)
      can?(current_user, :read_wiki, project)
    end
  end
end
