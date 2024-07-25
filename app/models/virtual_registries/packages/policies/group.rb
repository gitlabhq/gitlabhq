# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Policies
      class Group
        attr_reader :group

        delegate_missing_to :group

        def initialize(group)
          @group = group.root_ancestor
        end
      end
    end
  end
end
