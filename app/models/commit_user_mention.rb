# frozen_string_literal: true

class CommitUserMention < UserMention
  include Notes::WithAssociatedNote

  belongs_to :note
  belongs_to :namespace

  private

  def note_namespace_id
    note&.namespace_id || note&.project&.project_namespace_id
  end
end
