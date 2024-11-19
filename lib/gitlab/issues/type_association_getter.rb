# frozen_string_literal: true

module Gitlab
  module Issues
    module TypeAssociationGetter
      def self.call
        if Feature.enabled?(:issues_use_correct_work_item_type_id, :instance)
          :correct_work_item_type
        else
          :work_item_type
        end
      end
    end
  end
end
