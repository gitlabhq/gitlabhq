# frozen_string_literal: true

class NotePolicy < BasePolicy
  include Gitlab::Utils::StrongMemoize

  delegate { @subject.resource_parent }
  delegate { @subject.noteable if DeclarativePolicy.has_policy?(@subject.noteable) }

  condition(:is_author) { @user && @subject.author == @user }
  condition(:is_noteable_author) { @user && @subject.noteable.try(:author_id) == @user.id }

  condition(:editable, scope: :subject) { @subject.editable? }

  condition(:can_read_noteable) { can?(:"read_#{@subject.noteable_ability_name}") }
  condition(:commit_is_deleted) { @subject.for_commit? && @subject.noteable.blank? }

  condition(:for_design) { @subject.for_design? }

  condition(:is_visible) { @subject.system_note_with_references_visible_for?(@user) }

  condition(:confidential, scope: :subject) { @subject.confidential? }

  condition(:can_read_confidential) do
    access_level >= Gitlab::Access::REPORTER || @subject.noteable_assignee_or_author?(@user) || admin?
  end

  rule { ~editable }.prevent :admin_note

  # If user can't read the issue/MR/etc then they should not be allowed to do anything to their own notes
  rule { ~can_read_noteable }.policy do
    prevent :admin_note
    prevent :resolve_note
    prevent :reposition_note
    prevent :award_emoji
  end

  # Special rule for deleted commits
  rule { ~(can_read_noteable | commit_is_deleted) }.policy do
    prevent :read_note
  end

  rule { is_author }.policy do
    enable :read_note
    enable :admin_note
    enable :resolve_note
  end

  rule { ~is_visible }.policy do
    prevent :read_note
    prevent :admin_note
    prevent :resolve_note
    prevent :reposition_note
    prevent :award_emoji
  end

  rule { is_noteable_author }.policy do
    enable :resolve_note
  end

  rule { can_read_confidential }.policy do
    enable :mark_note_as_confidential
  end

  rule { confidential & ~can_read_confidential }.policy do
    prevent :read_note
    prevent :admin_note
    prevent :resolve_note
    prevent :reposition_note
    prevent :award_emoji
  end

  rule { can?(:admin_note) | (for_design & can?(:create_note)) }.policy do
    enable :reposition_note
  end

  def parent_namespace
    strong_memoize(:parent_namespace) do
      next if @subject.is_a?(PersonalSnippet)
      next @subject.noteable.group if @subject.noteable.is_a?(Epic)

      @subject.project
    end
  end

  def access_level
    return -1 if @user.nil?
    return -1 unless parent_namespace

    lookup_access_level!
  end

  def lookup_access_level!
    return ::Gitlab::Access::REPORTER if alert_bot?

    if parent_namespace.is_a?(Project)
      parent_namespace.team.max_member_access(@user.id)
    else
      parent_namespace.max_member_access_for_user(@user)
    end
  end
end
