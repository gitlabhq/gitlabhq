class OmniauthKerberosSpnegoController < ApplicationController
  include KerberosSpnegoHelper

  skip_before_action :authenticate_user!

  def negotiate
    if spnego_provided? && (krb_principal = spnego_credentials!(spnego_token))
      session[:kerberos_spnego_principal_name] = krb_principal
      send_final_spnego_response
      redirect_to user_kerberos_spnego_omniauth_callback_path
      return
    end

    headers['Www-Authenticate'] = spnego_challenge
    render 'errors/kerberos_denied.html.haml', layout: 'errors', status: 401
  end
end
