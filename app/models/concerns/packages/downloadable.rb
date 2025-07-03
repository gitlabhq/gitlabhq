# frozen_string_literal: true

module Packages
  module Downloadable
    extend ActiveSupport::Concern

    class_methods do
      def touch_last_downloaded_at(id)
        ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).without_sticky_writes do
          id_in(id).update_all(last_downloaded_at: Time.zone.now)
        end
      end
    end

    def touch_last_downloaded_at
      ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).without_sticky_writes do
        update_column(:last_downloaded_at, Time.zone.now)
      end
    end
  end
end

Packages::Downloadable.prepend_mod
Packages::Downloadable::ClassMethods.prepend_mod
