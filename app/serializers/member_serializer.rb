# frozen_string_literal: true

class MemberSerializer < BaseSerializer
  entity MemberEntity

  def represent(members, opts = {})
    LastGroupOwnerAssigner.new(opts[:group], members).execute unless opts[:source].is_a?(Project)
    Members::InvitedPrivateGroupAccessibilityAssigner
      .new(members, source: opts[:source], current_user: opts[:current_user]).execute

    super(members, opts)
  end
end
