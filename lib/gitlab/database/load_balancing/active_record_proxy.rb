module Gitlab
  module Database
    module LoadBalancing
      # Module injected into ActiveRecord::Base to allow proxying of subclasses.
      module ActiveRecordProxy
        def inherited(by)
          super(by)

          # The methods in ModelProxy will become available as class methods for
          # the class defined in `by`.
          by.singleton_class.prepend(ModelProxy)
        end
      end
    end
  end
end
