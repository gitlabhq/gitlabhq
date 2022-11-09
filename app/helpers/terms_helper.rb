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
end
