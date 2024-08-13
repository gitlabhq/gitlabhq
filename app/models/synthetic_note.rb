# frozen_string_literal: true

class SyntheticNote < Note
  self.allow_legacy_sti_class = true

  attr_accessor :resource_parent, :event

  def self.note_attributes(action, event, resource, resource_parent)
    resource ||= event.resource

    attrs = {
      system: true,
      author: event.user,
      created_at: event.created_at,
      updated_at: event.created_at,
      discussion_id: event.discussion_id,
      noteable: resource,
      event: event,
      system_note_metadata: ::SystemNoteMetadata.new(action: action, id: event.discussion_id),
      resource_parent: resource_parent,
      imported_from: event.respond_to?(:imported_from) ? event.imported_from : 'none'
    }

    if resource_parent.is_a?(Project)
      attrs[:project_id] = resource_parent.id
    end

    attrs
  end

  def project
    resource_parent if resource_parent.is_a?(Project)
  end

  def group
    resource_parent if resource_parent.is_a?(Group)
  end

  def note
    @note ||= note_text
  end

  def note_html
    raise NotImplementedError
  end

  private

  def note_text(html: false)
    raise NotImplementedError
  end
end
