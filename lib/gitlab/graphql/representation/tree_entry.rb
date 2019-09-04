# frozen_string_literal: true

module Gitlab
  module Graphql
    module Representation
      class TreeEntry < SimpleDelegator
        include GlobalID::Identification

        class << self
          def decorate(entries, repository)
            return if entries.nil?

            entries.map do |entry|
              if entry.is_a?(TreeEntry)
                entry
              else
                self.new(entry, repository)
              end
            end
          end
        end

        attr_accessor :repository

        def initialize(raw_entry, repository)
          @repository = repository

          super(raw_entry)
        end
      end
    end
  end
end
