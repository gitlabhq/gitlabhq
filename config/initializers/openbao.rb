# frozen_string_literal: true

Gitlab.ee do
  OpenbaoClient.configure do |c|
    c.host = if Gitlab.config.key?(:openbao) && Gitlab.config.openbao.key?(:proxy_address)
               Gitlab.config.openbao.proxy_address
             elsif Rails.env.test?
               # This matches the listener address in
               # `ee/spec/support/helpers/secrets_management/test_proxy.hcl`
               "http://127.0.0.1:9900"
             elsif Rails.env.development?
               "http://127.0.0.1:8100"
             else
               "https://127.0.0.1:8100"
             end

    c.base_path = 'v1'
  end
end
