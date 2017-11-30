module Notes
  class RenderService < BaseRenderer
    # Renders a collection of Note instances.
    #
    # notes - The notes to render.
    # project - The project to use for redacting.
    # user - The user viewing the notes.

    # Possible options:
    # requested_path - The request path.
    # project_wiki - The project's wiki.
    # ref - The current Git reference.
    # only_path - flag to turn relative paths into absolute ones.
    # xhtml - flag to save the html in XHTML
    def execute(notes, project, **opts)
      renderer = Banzai::ObjectRenderer.new(project, current_user, **opts)

      renderer.render(notes, :note)
    end
  end
end
