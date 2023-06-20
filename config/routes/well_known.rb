# frozen_string_literal: true

get '/.well-known/change-password', to: redirect('-/profile/password/edit'), status: 302
