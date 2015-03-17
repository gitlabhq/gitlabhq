class AuditEventService
  def initialize(author, entity, details = {})
    @author, @entity, @details = author, entity, details
  end

  def for_member(member)
    action = @details[:action]
    old_access_level = @details[:old_access_level]
    user_id = member.id
    user_name = member.user.name

    @details =
      case action
      when :destroy
        {
          remove: "user_access",
          target_id: user_id,
          target_type: "User",
          target_details: user_name,
        }
      when :create
        {
          add: "user_access",
          as: Gitlab::Access.options_with_owner.key(member.access_level.to_i),
          target_id: user_id,
          target_type: "User",
          target_details: user_name,
        }
      when :update
        {
          change: "access_level",
          from: old_access_level,
          to: member.human_access,
          target_id: user_id,
          target_type: "User",
          target_details: user_name,
        }
      end
  end

  def security_event
    SecurityEvent.create(
      author_id: @author.id,
      entity_id: @entity.id,
      entity_type: @entity.class.name,
      details: @details
    )
  end
end
