class GpgKeySubkey < ActiveRecord::Base
  include ShaAttribute

  sha_attribute :keyid
  sha_attribute :fingerprint

  belongs_to :gpg_key

  def method_missing(m, *a, &b)
    return super unless gpg_key.respond_to?(m)

    gpg_key.public_send(m, *a, &b) # rubocop:disable GitlabSecurity/PublicSend
  end

  def respond_to_missing?(method, include_private = false)
    gpg_key.respond_to?(method, include_private) || super
  end
end
