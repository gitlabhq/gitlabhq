# frozen_string_literal: true

class StateNote < SyntheticNote
  include Gitlab::Utils::StrongMemoize

  self.allow_legacy_sti_class = true

  def self.from_event(event, resource: nil, resource_parent: nil)
    attrs = note_attributes(action_by(event), event, resource, resource_parent)

    StateNote.new(attrs)
  end

  def note_html
    @note_html ||= Banzai::Renderer.cacheless_render_field(self, :note, { group: group, project: project })
  end

  private

  def note_text(html: false)
    if event.state == 'closed'
      if event.close_after_error_tracking_resolve
        return 'resolved the corresponding error and closed the issue'
      end

      if event.close_auto_resolve_prometheus_alert
        return 'automatically closed this incident because the alert resolved'
      end
    end

    return "merged manually" if event.state == 'merged' && event_source.is_a?(Commit)

    body = event.state.dup
    body << " with #{event_source.gfm_reference(project)}" if event_source
    body
  end

  def event_source
    strong_memoize(:event_source) do
      if event.source_commit
        project&.commit(event.source_commit)
      else
        event.source_merge_request
      end
    end
  end

  def self.action_by(event)
    event.state == 'reopened' ? 'opened' : event.state
  end
end
