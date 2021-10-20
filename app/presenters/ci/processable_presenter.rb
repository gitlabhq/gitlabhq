# frozen_string_literal: true

module Ci
  class ProcessablePresenter < CommitStatusPresenter
    presents ::Ci::Processable
  end
end
