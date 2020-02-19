# frozen_string_literal: true

class MilestoneNote < ::Note
  attr_accessor :resource_parent, :event, :milestone

  def self.from_event(event, resource: nil, resource_parent: nil)
    resource ||= event.resource

    attrs = {
        system: true,
        author: event.user,
        created_at: event.created_at,
        noteable: resource,
        milestone: event.milestone,
        event: event,
        system_note_metadata: ::SystemNoteMetadata.new(action: 'milestone'),
        resource_parent: resource_parent
    }

    if resource_parent.is_a?(Project)
      attrs[:project_id] = resource_parent.id
    end

    MilestoneNote.new(attrs)
  end

  def note
    @note ||= note_text
  end

  def note_html
    @note_html ||= Banzai::Renderer.cacheless_render_field(self, :note, { group: group, project: project })
  end

  def project
    resource_parent if resource_parent.is_a?(Project)
  end

  def group
    resource_parent if resource_parent.is_a?(Group)
  end

  private

  def note_text(html: false)
    format = milestone&.group_milestone? ? :name : :iid
    milestone.nil? ? 'removed milestone' : "changed milestone to #{milestone.to_reference(project, format: format)}"
  end
end
