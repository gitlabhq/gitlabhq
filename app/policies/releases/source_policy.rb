# frozen_string_literal: true

module Releases
  class SourcePolicy < BasePolicy
    delegate { @subject.project }
  end
end
