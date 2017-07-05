module EE
  module Projects
    module MergeRequests
      module CreationsController
        extend ActiveSupport::Concern

        private

        def define_new_vars
          super
          set_suggested_approvers
        end
      end
    end
  end
end
