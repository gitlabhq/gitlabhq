module Noteable
  def discussion_notes
    notes
  end

  delegate :find_discussion, to: :discussion_notes

  def discussions
    @discussions ||= discussion_notes
      .inc_relations_for_view
      .discussions(self)
  end

  def grouped_diff_discussions
    notes.inc_relations_for_view.grouped_diff_discussions
  end
end
