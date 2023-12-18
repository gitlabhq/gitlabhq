# frozen_string_literal: true

get '/.well-known/change-password', to: redirect('-/user_settings/password/edit'), status: 302
get '/.well-known/security.txt', to: 'well_known#security_txt'
