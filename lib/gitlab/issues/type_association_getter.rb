# frozen_string_literal: true

module Gitlab
  module Issues
    module TypeAssociationGetter
      def self.call
        :correct_work_item_type
      end
    end
  end
end
