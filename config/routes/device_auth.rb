# frozen_string_literal: true

namespace :oauth do
  resource :device, only: [] do
    post :confirm, to: 'device_authorizations#confirm'
  end
end
