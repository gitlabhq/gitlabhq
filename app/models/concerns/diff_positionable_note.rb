# frozen_string_literal: true
module DiffPositionableNote
  extend ActiveSupport::Concern

  included do
    delegate :on_text?, :on_image?, to: :position, allow_nil: true
    before_validation :set_original_position, on: :create
    before_validation :update_position, on: :create, if: :on_text?, unless: :importing?

    serialize :original_position, Gitlab::Diff::Position # rubocop:disable Cop/ActiveRecordSerialize
    serialize :position, Gitlab::Diff::Position # rubocop:disable Cop/ActiveRecordSerialize
    serialize :change_position, Gitlab::Diff::Position # rubocop:disable Cop/ActiveRecordSerialize

    validate :diff_refs_match_commit, if: :for_commit?
  end

  %i(original_position position change_position).each do |meth|
    define_method "#{meth}=" do |new_position|
      if new_position.is_a?(String)
        new_position = JSON.parse(new_position) rescue nil
      end

      if new_position.is_a?(Hash)
        new_position = new_position.with_indifferent_access
        new_position = Gitlab::Diff::Position.new(new_position)
      end

      return if new_position == read_attribute(meth)

      super(new_position)
    end
  end

  def supported?
    for_commit? || self.noteable.has_complete_diff_refs?
  end

  def active?(diff_refs = nil)
    return false unless supported?
    return true if for_commit?

    diff_refs ||= noteable.diff_refs

    self.position.diff_refs == diff_refs
  end

  def set_original_position
    return unless position

    self.original_position = self.position.dup unless self.original_position&.complete?
  end

  def update_position
    return unless supported?
    return if for_commit?

    return if active?
    return unless position

    tracer = Gitlab::Diff::PositionTracer.new(
      project: self.project,
      old_diff_refs: self.position.diff_refs,
      new_diff_refs: self.noteable.diff_refs,
      paths: self.position.paths
    )

    result = tracer.trace(self.position)
    return unless result

    if result[:outdated]
      self.change_position = result[:position]
    else
      self.position = result[:position]
    end
  end

  def diff_refs_match_commit
    return if self.original_position.diff_refs == commit&.diff_refs

    errors.add(:commit_id, 'does not match the diff refs')
  end
end
