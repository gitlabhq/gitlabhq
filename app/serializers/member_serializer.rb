# frozen_string_literal: true

class MemberSerializer < BaseSerializer
  entity MemberEntity

  def represent(members, opts = {})
    LastGroupOwnerAssigner.new(opts[:group], members).execute unless opts[:source].is_a?(Project)

    super(members, opts)
  end
end
