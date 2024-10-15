# frozen_string_literal: true

class LabelNote < SyntheticNote
  self.allow_legacy_sti_class = true

  attr_accessor :resource_parent
  attr_reader :events

  def self.from_event(event, resource: nil, resource_parent: nil)
    attrs = note_attributes('label', event, resource, resource_parent).merge(events: [event])

    LabelNote.new(attrs)
  end

  def self.from_events(events, resource: nil, resource_parent: nil)
    resource ||= events.first.issuable

    label_note = from_event(events.first, resource: resource, resource_parent: resource_parent)
    label_note.events = events.sort_by { |e| e.label&.name.to_s }

    label_note
  end

  def events=(events)
    @events = events

    update_outdated_markdown
  end

  def cached_html_up_to_date?(markdown_field)
    true
  end

  def note_html
    @note_html ||= "<p dir=\"auto\">#{note_text(html: true)}</p>"
  end

  private

  def update_outdated_markdown
    events.each do |event|
      if event.outdated_markdown?
        event.refresh_invalid_reference
      end
    end
  end

  def note_text(html: false)
    added = labels_str(label_refs_by_action('add', html).uniq, prefix: 'added')
    removed = labels_str(label_refs_by_action('remove', html).uniq, prefix: 'removed')

    [added, removed].compact.join(' and ')
  end

  # returns string containing added/removed labels including
  # count of deleted labels:
  #
  # added ~1 ~2 + 1 deleted label
  # added 3 deleted labels
  # added ~1 ~2 labels
  def labels_str(label_refs, prefix: '')
    existing_refs = label_refs.select(&:present?)
    refs_str = existing_refs.empty? ? nil : existing_refs.join(' ')

    deleted = label_refs.count - existing_refs.count
    deleted_str = deleted == 0 ? nil : "#{deleted} deleted"

    return unless refs_str || deleted_str

    label_list_str = [refs_str, deleted_str].compact.join(' + ')
    suffix = ' label'.pluralize(deleted > 0 ? deleted : existing_refs.count)

    "#{prefix} #{label_list_str} #{suffix.squish}"
  end

  def label_refs_by_action(action, html)
    field = html ? :reference_html : :reference

    events.select { |e| e.action == action }.map(&field)
  end
end

LabelNote.prepend_mod_with('LabelNote')
