# frozen_string_literal: true

module Releases
  class LinkPolicy < BasePolicy
    delegate { @subject.release }
  end
end
