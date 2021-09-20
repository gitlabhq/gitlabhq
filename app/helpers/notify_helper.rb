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

  def invited_join_url(token, member)
    additional_params = { invite_type: Emails::Members::INITIAL_INVITE }

    # order important below to our scheduled testing of these
    # `from` experiment will be after the `text` on, but we may not cleanup
    # from the `text` one by the time we run the `from` experiment,
    # therefore we want to support `text` being fully enabled
    # but if `from` is also enabled, then we only care about `from`
    if experiment(:invite_email_from, actor: member).enabled?
      additional_params[:experiment_name] = 'invite_email_from'
    elsif experiment(:invite_email_preview_text, actor: member).enabled?
      additional_params[:experiment_name] = 'invite_email_preview_text'
    end

    invite_url(token, additional_params)
  end
end
