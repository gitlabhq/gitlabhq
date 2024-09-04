# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      class UpstreamPolicy < ::BasePolicy
        delegate { @subject.registry }
      end
    end
  end
end
