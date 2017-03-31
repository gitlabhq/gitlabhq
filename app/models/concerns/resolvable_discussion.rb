module ResolvableDiscussion
  extend ActiveSupport::Concern

  included do
    memoized_values.push(
      :resolvable,
      :resolved,
      :first_note,
      :first_note_to_resolve,
      :last_resolved_note,
      :last_note
    )

    delegate  :resolved_at,
              :resolved_by,

              to: :last_resolved_note,
              allow_nil: true
  end

  # Keep this method in sync with the `potentially_resolvable` scope on `ResolvableNote`
  def potentially_resolvable?
    for_merge_request?
  end

  def resolvable?
    return @resolvable if @resolvable.present?

    @resolvable = potentially_resolvable? && notes.any?(&:resolvable?)
  end

  def resolved?
    return @resolved if @resolved.present?

    @resolved = resolvable? && notes.none?(&:to_be_resolved?)
  end

  def first_note
    @first_note ||= notes.first
  end

  def first_note_to_resolve
    return unless resolvable?

    @first_note_to_resolve ||= notes.find(&:to_be_resolved?)
  end

  def last_resolved_note
    return unless resolved?

    @last_resolved_note ||= resolved_notes.sort_by(&:resolved_at).last
  end

  def resolved_notes
    notes.select(&:resolved?)
  end

  def to_be_resolved?
    resolvable? && !resolved?
  end

  def can_resolve?(current_user)
    return false unless current_user
    return false unless resolvable?

    current_user == self.noteable.author ||
      current_user.can?(:resolve_note, self.project)
  end

  def resolve!(current_user)
    return unless resolvable?

    update { |notes| notes.resolve!(current_user) }
  end

  def unresolve!
    return unless resolvable?

    update { |notes| notes.unresolve! }
  end
end
