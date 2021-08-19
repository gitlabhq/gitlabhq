# frozen_string_literal: true

module Ci
  class RunnerPresenter < Gitlab::View::Presenter::Delegated
    presents :runner

    def locked?
      read_attribute(:locked) && project_type?
    end
    alias_method :locked, :locked?
  end
end
