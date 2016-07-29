module KerberosSpnegoHelper
  include ActionController::HttpAuthentication::Basic

  attr_reader :spnego_response_token

  def allow_basic_auth?
    if Gitlab.config.kerberos.enabled && Gitlab.config.kerberos.use_dedicated_port
      !request_uses_kerberos_dedicated_port?
    else
      true
    end
  end

  def allow_kerberos_spnego_auth?
    return false unless Gitlab.config.kerberos.enabled

    if Gitlab.config.kerberos.use_dedicated_port
      request_uses_kerberos_dedicated_port?
    else
      true
    end
  end

  def request_uses_kerberos_dedicated_port?
    request.env['SERVER_PORT'] == Gitlab.config.kerberos.port.to_s
  end

  def spnego_challenge
    if spnego_response_token
      "Negotiate #{::Base64.strict_encode64(spnego_response_token)}"
    else
      'Negotiate'
    end
  end

  def spnego_provided?
    request.authorization.present? && (auth_scheme(request) == 'Negotiate')
  end

  def send_final_spnego_response
    headers['Www-Authenticate'] = spnego_challenge if spnego_response_token
  end

  def find_kerberos_user
    krb_principal = spnego_credentials!(spnego_token)
    return unless krb_principal

    identity = ::Identity.find_by(provider: :kerberos, extern_uid: krb_principal)
    identity.user if identity
  end

  # The Kerberos backend will translate spnego_token into a Kerberos
  # principal and/or provide a value for @spnego_response_token.
  def spnego_credentials!(spnego_token)
    require 'gssapi'
    gss = GSSAPI::Simple.new(nil, nil, Gitlab.config.kerberos.keytab)
    # the GSSAPI::Simple constructor transforms a nil service name into a default value, so
    # pass service name to acquire_credentials explicitly to support the special meaning of nil
    gss_service_name =
      if Gitlab.config.kerberos.service_principal_name.present?
        gss.import_name(Gitlab.config.kerberos.service_principal_name)
      else
        nil # accept any valid service principal name from keytab
      end
    gss.acquire_credentials(gss_service_name) # grab credentials from keytab

    # Decode token
    gss_result = gss.accept_context(spnego_token)

    # gss_result will be 'true' if nothing has to be returned to the client
    @spnego_response_token = gss_result if gss_result && gss_result != true

    # Return user principal name if authentication succeeded
    gss.display_name
  rescue GSSAPI::GssApiError => ex
    Rails.logger.error "#{self.class.name}: failed to process Negotiate/Kerberos authentication: #{ex.message}"
    false
  end

  def spnego_token
    Base64.strict_decode64(auth_param(request))
  end
end
