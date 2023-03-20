# frozen_string_literal: true

module ActiveRecord
  module Associations
    class Preloader
      def initialize(records: nil, associations: nil)
        super()

        @records = records
        @associations = associations
      end

      def call
        preload(@records, @associations)
      end

      class NullPreloader
        def self.new(*args, **kwargs)
          self
        end

        def self.run
          self
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
