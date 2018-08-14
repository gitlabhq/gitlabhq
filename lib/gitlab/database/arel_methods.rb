module Gitlab
  module Database
    module ArelMethods
      private

      # In Arel 7.0.0 (Arel 7.1.4 is used in Rails 5.0) the `engine` parameter of `Arel::UpdateManager#initializer`
      # was removed.
      # Remove this file and inline this method when removing rails5? code.
      def arel_update_manager
        if Gitlab.rails5?
          Arel::UpdateManager.new
        else
          Arel::UpdateManager.new(ActiveRecord::Base)
        end
      end
    end
  end
end
