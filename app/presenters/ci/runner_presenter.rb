# frozen_string_literal: true

module Ci
  class RunnerPresenter < Gitlab::View::Presenter::Delegated
    presents ::Ci::Runner, as: :runner

    delegator_override :locked?
    def locked?
      read_attribute(:locked) && project_type?
    end

    delegator_override :locked
    alias_method :locked, :locked?

    def executor_name
      Ci::Runner::EXECUTOR_TYPE_TO_NAMES[executor_type&.to_sym]
    end

    def paused
      !active
    end
  end
end
