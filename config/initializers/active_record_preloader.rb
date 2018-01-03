module ActiveRecord
  module Associations
    class Preloader
      module NoCommitPreloader
        def preloader_for(reflection, owners, rhs_klass)
          return NullPreloader if rhs_klass == ::Commit

          super
        end
      end

      prepend NoCommitPreloader
    end
  end
end
