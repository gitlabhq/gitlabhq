# frozen_string_literal: true

class StateNote < SyntheticNote
  def self.from_event(event, resource: nil, resource_parent: nil)
    attrs = note_attributes(event.state, event, resource, resource_parent)

    StateNote.new(attrs)
  end

  def note_html
    @note_html ||= "<p dir=\"auto\">#{note_text(html: true)}</p>"
  end

  private

  def note_text(html: false)
    event.state
  end
end
