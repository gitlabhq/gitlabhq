# frozen_string_literal: true

module Releases
  class SourcePolicy < BasePolicy
    delegate { @subject.project }

    rule { can?(:public_access) | can?(:reporter_access) }.policy do
      enable :read_release_sources
    end

    rule { ~can?(:read_release) }.prevent :read_release_sources
  end
end
