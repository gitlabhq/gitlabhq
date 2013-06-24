# == Mentionable concern
#
# Contains common functionality shared between Issues and Notes
#
# Used by Issue, Note
#
module Mentionable
  extend ActiveSupport::Concern

  def mentioned_users
    users = []
    return users if mentionable_text.blank?
    has_project = self.respond_to? :project
    matches = mentionable_text.scan(/@[a-zA-Z][a-zA-Z0-9_\-\.]*/)
    matches.each do |match|
      identifier = match.delete "@"
      if has_project
        id = project.users_projects.joins(:user).where(users: { username: identifier }).pluck(:user_id).first
      else
        id = User.where(username: identifier).pluck(:id).first
      end
      users << User.find(id) unless id.blank?
    end
    users.uniq
  end

  def mentionable_text
    if self.class == Issue
      description
    elsif self.class == Note
      note
    else
      nil
    end
  end

end
