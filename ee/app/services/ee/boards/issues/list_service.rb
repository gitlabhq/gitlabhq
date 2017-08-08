module EE
  module Boards
    module Issues
      module ListService
        def set_parent
          if @parent.is_a?(Group)
            params[:group_id] = @parent.id
          else
            super
          end
        end
      end
    end
  end
end
