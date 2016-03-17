class GroupsFinder
  def execute(current_user = nil)
    segments = all_groups(current_user)

    if segments.length > 1
      union = Gitlab::SQL::Union.new(segments.map { |s| s.select(:id) })
      Group.where("namespaces.id IN (#{union.to_sql})").order_id_desc
    else
      segments.first
    end
  end

  private

  def all_groups(current_user)
    if current_user
      user_groups(current_user)
    else
      [Group.unscoped.public_only]
    end
  end

  def user_groups(current_user)
    if current_user.external?
      [current_user.authorized_groups, Group.unscoped.public_only]
    else
      [current_user.authorized_groups, Group.unscoped.public_and_internal_only]
    end
  end
end
