# frozen_string_literal: true

module Gitlab
  module Database
    # Module that can be injected into a ActiveRecord::Relation to make it
    # read-only.
    module ReadOnlyRelation
      [:delete, :delete_all, :update, :update_all].each do |method|
        define_method(method) do |*args|
          raise(
            ActiveRecord::ReadOnlyRecord,
            "This relation is marked as read-only"
          )
        end
      end
    end
  end
end
