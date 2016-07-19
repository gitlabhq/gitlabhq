module Banzai
  module NoteRenderer
    # Renders a collection of Note instances.
    #
    # notes - The notes to render.
    # project - The project to use for rendering/redacting.
    # user - The user viewing the notes.
    # path - The request path.
    # wiki - The project's wiki.
    # git_ref - The current Git reference.
    def self.render(notes, project, user = nil, path = nil, wiki = nil, git_ref = nil)
      renderer = ObjectRenderer.new(project,
                                    user,
                                    requested_path: path,
                                    project_wiki: wiki,
                                    ref: git_ref,
                                    pipeline: :note)

      renderer.render(notes, :note)
    end
  end
end
