# frozen_string_literal: true

module NotifyHelper
  def merge_request_reference_link(entity, *args)
    link_to(entity.to_reference, merge_request_url(entity, *args))
  end

  def issue_reference_link(entity, *args, full: false)
    link_to(entity.to_reference(full: full), issue_url(entity, *args))
  end

  def invited_role_description(role_name)
    case role_name
    when "Guest"
      s_("InviteEmail|As a guest, you can view projects, leave comments, and create issues.")
    when "Reporter"
      s_("InviteEmail|As a reporter, you can view projects and reports, and leave comments on issues.")
    when "Developer"
      s_("InviteEmail|As a developer, you have full access to projects, so you can take an idea from concept to production.")
    when "Maintainer"
      s_("InviteEmail|As a maintainer, you have full access to projects. You can push commits to the default branch and deploy to production.")
    when "Owner"
      s_("InviteEmail|As an owner, you have full access to projects and can manage access to the group, including inviting new members.")
    when "Minimal Access"
      s_("InviteEmail|As a user with minimal access, you can view the high-level group from the UI and API.")
    end
  end

  def invited_to_description(source)
    case source
    when "project"
      s_('InviteEmail|Projects can be used to host your code, track issues, collaborate on code, and continuously build, test, and deploy your app with built-in GitLab CI/CD.')
    when "group"
      s_('InviteEmail|Groups assemble related projects together and grant members access to several projects at once.')
    end
  end
end
