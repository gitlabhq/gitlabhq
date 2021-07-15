# frozen_string_literal: true

# A discussion on merge request or commit diffs consisting of `DiffNote` notes.
#
# A discussion of this type can be resolvable.
class DiffDiscussion < Discussion
  include DiscussionOnDiff

  def self.note_class
    DiffNote
  end

  delegate  :position,
            :original_position,
            :change_position,
            :diff_note_positions,
            :on_text?,
            :on_image?,
            to: :first_note

  def legacy_diff_discussion?
    false
  end

  def merge_request_version_params
    return unless for_merge_request?

    version_params = get_params

    return version_params unless on_merge_request_commit? && commit_id

    version_params ||= {}
    version_params.tap do |params|
      params[:commit_id] = commit_id
    end
  end

  def reply_attributes
    super.merge(
      original_position: original_position.to_json,
      position: position.to_json
    )
  end

  def cache_key
    [
      super,
      Digest::SHA1.hexdigest(position.to_json)
    ].join(':')
  end

  private

  def get_params
    return {} if active?

    noteable.version_params_for(position.diff_refs)
  end
end
