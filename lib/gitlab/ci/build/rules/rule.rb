# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule
        attr_accessor :attributes

        def self.fabricate_list(list)
          list.map(&method(:new)) if list
        end

        def initialize(spec)
          @clauses    = []
          @attributes = {}

          spec.each do |type, value|
            if clause = Clause.fabricate(type, value)
              @clauses << clause
            else
              @attributes.merge!(type => value)
            end
          end
        end

        def matches?(pipeline, context)
          @clauses.all? { |clause| clause.satisfied_by?(pipeline, context) }
        end
      end
    end
  end
end
