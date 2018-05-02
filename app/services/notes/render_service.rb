module Notes
  class RenderService < BaseRenderer
    # Renders a collection of Note instances.
    #
    # notes - The notes to render.
    #
    # Possible options:
    #
    # requested_path - The request path.
    # project_wiki - The project's wiki.
    # ref - The current Git reference.
    # only_path - flag to turn relative paths into absolute ones.
    # xhtml - flag to save the html in XHTML
    def execute(notes, options = {})
      Banzai::ObjectRenderer
        .new(user: current_user, redaction_context: options)
        .render(notes, :note)
    end
  end
end
