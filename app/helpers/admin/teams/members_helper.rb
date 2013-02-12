module Admin::Teams::MembersHelper
  def member_since(team, member)
    team.user_team_user_relationships.find_by_user_id(member).created_at
  end
end
