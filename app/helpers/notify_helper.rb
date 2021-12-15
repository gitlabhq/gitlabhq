# frozen_string_literal: true

module NotifyHelper
  def merge_request_reference_link(entity, *args)
    link_to(entity.to_reference, merge_request_url(entity, *args))
  end

  def issue_reference_link(entity, *args, full: false)
    link_to(entity.to_reference(full: full), issue_url(entity, *args))
  end

  def invited_to_description(source)
    default_description =
      case source
      when Project
        s_('InviteEmail|Projects are used to host and collaborate on code, track issues, and continuously build, test, and deploy your app with built-in GitLab CI/CD.')
      when Group
        s_('InviteEmail|Groups assemble related projects together and grant members access to several projects at once.')
      end

    (source.description || default_description).truncate(200, separator: ' ')
  end
end
