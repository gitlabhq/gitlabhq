# frozen_string_literal: true

module Packages
  module Policies
    class Group
      attr_accessor :group

      delegate_missing_to :group

      def initialize(group)
        @group = group
      end
    end
  end
end
