# frozen_string_literal: true

module TermsHelper
  def terms_data(terms, redirect)
    redirect_params = { redirect: redirect } if redirect

    {
      terms: markdown_field(terms, :terms),
      permissions: {
        can_accept: can?(current_user, :accept_terms, terms),
        can_decline: can?(current_user, :decline_terms, terms)
      },
      paths: {
        accept: accept_term_path(terms, redirect_params),
        decline: decline_term_path(terms, redirect_params),
        root: root_path
      }
    }.to_json
  end

  def terms_service_notice_link(button_text)
    terms_link = link_to('', terms_path, target: '_blank', rel: 'noopener noreferrer')

    safe_format(
      s_(
        'SignUp|By clicking %{button_text} or registering through a third party you accept the %{link_start}Terms ' \
          'of Use and acknowledge the Privacy Statement and Cookie Policy%{link_end}.'
      ),
      tag_pair(terms_link, :link_start, :link_end),
      button_text: button_text
    )
  end
end

TermsHelper.prepend_mod
