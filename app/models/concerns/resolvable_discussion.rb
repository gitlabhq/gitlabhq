module ResolvableDiscussion
  extend ActiveSupport::Concern
  include ::Gitlab::Utils::StrongMemoize

  included do
    # A number of properties of this `Discussion`, like `first_note` and `resolvable?`, are memoized.
    # When this discussion is resolved or unresolved, the values of these properties potentially change.
    # To make sure all memoized values are reset when this happens, `update` resets all instance variables with names in
    # `memoized_variables`. If you add a memoized method in `ResolvableDiscussion` or any `Discussion` subclass,
    # please make sure the instance variable name is added to `memoized_values`, like below.
    cattr_accessor :memoized_values, instance_accessor: false do
      []
    end

    memoized_values.push(
      :resolvable,
      :resolved,
      :first_note,
      :first_note_to_resolve,
      :last_resolved_note,
      :last_note
    )

    delegate :potentially_resolvable?, to: :first_note

    delegate  :resolved_at,
              :resolved_by,
              :resolved_by_push?,

              to: :last_resolved_note,
              allow_nil: true
  end

  def resolvable?
    strong_memoize(:resolvable) do
      potentially_resolvable? && notes.any?(&:resolvable?)
    end
  end

  def resolved?
    strong_memoize(:resolved) do
      resolvable? && notes.none?(&:to_be_resolved?)
    end
  end

  def first_note
    strong_memoize(:first_note) do
      notes.first
    end
  end

  def first_note_to_resolve
    return unless resolvable?

    strong_memoize(:first_note_to_resolve) do
      notes.find(&:to_be_resolved?)
    end
  end

  def last_resolved_note
    return unless resolved?

    strong_memoize(:last_resolved_note) do
      resolved_notes.sort_by(&:resolved_at).last
    end
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

  private

  def update
    # Do not select `Note.resolvable`, so that system notes remain in the collection
    notes_relation = Note.where(id: notes.map(&:id))

    yield(notes_relation)

    # Set the notes array to the updated notes
    @notes = notes_relation.fresh.to_a # rubocop:disable Gitlab/ModuleWithInstanceVariables

    self.class.memoized_values.each do |name|
      clear_memoization(name)
    end
  end
end
