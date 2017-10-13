module EE
  module Gitlab
    module Auth
      module Result
        def success?
          raise NotImplementedError.new unless defined?(super)

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
