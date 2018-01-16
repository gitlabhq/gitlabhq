module EE
  module Gitlab
    module Auth
      module Result
        extend ::Gitlab::Utils::Override

        override :success?
        def success?
          type == :geo || super
        end

        def geo?(for_project)
          type == :geo &&
            project &&
            project == for_project
        end
      end
    end
  end
end
