# frozen_string_literal: true

module KerberosHelper
  def allow_basic_auth?
    true # different behavior in GitLab Enterprise Edition
  end

  def allow_kerberos_auth?
    false # different behavior in GitLab Enterprise Edition
  end
end

KerberosHelper.prepend_mod_with('KerberosHelper')
