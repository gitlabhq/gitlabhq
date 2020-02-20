module ActiveRecord
  module Associations
    class Preloader
      class NullPreloader
        def self.new(klass, owners, reflection, preload_scope)
          self
        end

        def self.run
        end

        def self.preloaded_records
          []
        end
      end

      module NoCommitPreloader
        def preloader_for(reflection, owners)
          return NullPreloader if owners.first.association(reflection.name).klass == ::Commit

          super
        end
      end

      prepend NoCommitPreloader
    end
  end
end
