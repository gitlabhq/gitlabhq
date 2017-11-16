module Events
  class RenderService < BaseRenderer
    def execute(events, atom_request: false)
      events.map(&:note).compact.group_by(&:project).each do |project, notes|
        render_notes(notes, project, atom_request)
      end
    end

    private

    def render_notes(notes, project, atom_request)
      Notes::RenderService.new(current_user).execute(notes, project, render_options(atom_request))
    end

    def render_options(atom_request)
      return {} unless atom_request

      { only_path: false, xhtml: true }
    end
  end
end
