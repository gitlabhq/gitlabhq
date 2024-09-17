# frozen_string_literal: true

if Gitlab.config.key?(:openbao)
  OpenbaoClient.configure do |c|
    c.host = Gitlab.config.openbao.proxy_address
    c.base_path = 'v1'
  end
end
