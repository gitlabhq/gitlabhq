# frozen_string_literal: true

class MilestoneNote < SyntheticNote
  self.allow_legacy_sti_class = true

  attr_accessor :milestone

  def self.from_event(event, resource: nil, resource_parent: nil)
    attrs = note_attributes('milestone', event, resource, resource_parent).merge(milestone: event.milestone)

    MilestoneNote.new(attrs)
  end

  def note_html
    @note_html ||= Banzai::Renderer.cacheless_render_field(self, :note, { group: group, project: project })
  end

  private

  def note_text(html: false)
    format = milestone&.group_milestone? ? :name : :iid
    reference = milestone&.to_reference(project, format: format, full: true, absolute_path: true)
    event.remove? ? "removed milestone #{reference}" : "changed milestone to #{reference}"
  end
end
