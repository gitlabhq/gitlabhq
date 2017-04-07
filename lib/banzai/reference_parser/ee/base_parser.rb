module Banzai
  module ReferenceParser
    module EE
      module BaseParser
        # override
        # TODO: this override would make more sense in
        # the policies framework, but CE currently
        # manually checks for team membership and the like.
        def nodes_user_can_reference(user, nodes)
          return [] if user.support_bot?

          super
        end
      end
    end
  end
end
