module Ci
  class Build
    class Presenter < Gitlab::View::Presenter::Delegated
      presents :build

      def erased_by_user?
        # Build can be erased through API, therefore it does not have
        # `erase_by` user assigned in that case.
        erased? && erased_by
      end

      def erased_by_name
        erased_by.name if erased_by
      end
    end
  end
end
