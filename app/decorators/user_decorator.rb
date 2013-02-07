class UserDecorator < ApplicationDecorator
  decorates :user

  def avatar_image size = 16
    h.image_tag h.gravatar_icon(self.email, size), class: "avatar #{"s#{size}"}", width: size
  end

  def tm_of(project)
    project.team_member_by_id(self.id)
  end

  def name_with_email
    "#{name} (#{email})"
  end
end
