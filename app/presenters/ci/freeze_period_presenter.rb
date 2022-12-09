# frozen_string_literal: true

module Ci
  class FreezePeriodPresenter < Gitlab::View::Presenter::Delegated
    presents ::Ci::FreezePeriod, as: :freeze_period

    def start_time
      return freeze_period.time_start if freeze_period.active?

      freeze_period.next_time_start
    end
  end
end
