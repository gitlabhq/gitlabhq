# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Fixers
        def self.create_for(inconsistency)
          case inconsistency.type
          when 'Gitlab::Schema::Validation::Validators::MissingIndexes'
            MissingIndex.new(inconsistency)
          else
            Base.new(inconsistency)
          end
        end

        class Base
          attr_reader :table_name

          def initialize(inconsistency)
            data = inconsistency.to_h
            @table_name = data[:table_name]
            @structure_sql_statement = data[:structure_sql_statement]
          end

          def statement
            structure_sql_statement&.chomp
          end

          private

          attr_reader :structure_sql_statement
        end
      end
    end
  end
end
