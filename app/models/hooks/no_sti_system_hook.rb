# frozen_string_literal: true

class NoStiSystemHook < SystemHook # rubocop:disable Gitlab/BoundedContexts, Gitlab/NamespacedClass -- Copied from SystemHook
  self.table_name = "system_hooks"

  undef :web_hook_logs

  attr_encrypted :token,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-gcm',
    key: Settings.attr_encrypted_db_key_base_32,
    encode: false,
    encode_iv: false

  attr_encrypted :url,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-gcm',
    key: Settings.attr_encrypted_db_key_base_32,
    encode: false,
    encode_iv: false

  def decrypt_url_was
    self.class.decrypt_url(encrypted_url_was, iv: encrypted_url_iv_was)
  end
end
