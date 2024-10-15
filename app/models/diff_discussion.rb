# frozen_string_literal: true

# A discussion on merge request or commit diffs consisting of `DiffNote` notes.
#
# A discussion of this type can be resolvable.
class DiffDiscussion < Discussion
  include DiscussionOnDiff

  def self.note_class
    DiffNote
  end

  delegate :position,
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
      original_position: Gitlab::Json.dump(original_position.to_h),
      position: Gitlab::Json.dump(position.to_h),
      line_code: line_code
    )
  end

  def cache_key
    positions_json = diff_note_positions.map { |dnp| Gitlab::Json.dump(dnp.position) }
    positions_sha = Digest::SHA1.hexdigest(positions_json.join(':')) if positions_json.any?

    [
      super,
      Digest::SHA1.hexdigest(Gitlab::Json.dump(position)),
      positions_sha
    ].join(':')
  end

  private

  def get_params
    return {} if active?

    noteable.version_params_for(position.diff_refs)
  end
end
