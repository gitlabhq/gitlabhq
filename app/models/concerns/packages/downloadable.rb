# frozen_string_literal: true

module Packages
  module Downloadable
    extend ActiveSupport::Concern

    def touch_last_downloaded_at
      ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).without_sticky_writes do
        update_column(:last_downloaded_at, Time.zone.now)
      end
    end
  end
end

Packages::Downloadable.prepend_mod
