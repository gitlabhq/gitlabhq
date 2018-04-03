module EE
  module Gitlab
    module EtagCaching
      module Router
        module ClassMethods
          def match(path)
            epic_route = ::Gitlab::EtagCaching::Router::Route.new(
              %r(^/groups/#{::Gitlab::PathRegex.full_namespace_route_regex}/-/epics/\d+/notes\z),
              'epic_notes'
            )

            return epic_route if epic_route.regexp.match(path)

            super
          end
        end

        def self.prepended(base)
          base.singleton_class.prepend ClassMethods
        end
      end
    end
  end
end
