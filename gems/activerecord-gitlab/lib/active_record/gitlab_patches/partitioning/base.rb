# frozen_string_literal: true

if ::ActiveRecord::VERSION::STRING >= "7.2"
  raise 'New version of active-record detected, please remove or update this patch'
end

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module ActiveRecord
  module GitlabPatches
    module Partitioning
      module Base
        if ::ActiveRecord::VERSION::STRING <= "7.1"
          def _query_constraints_hash
            if self.class.query_constraints_list.nil?
              { @primary_key => id_in_database }
            else
              self.class.query_constraints_list.index_with do |column_name|
                attribute_in_database(column_name)
              end
            end
          end
        end

        module ClassMethods
          def query_constraints(*columns_list)
            raise ArgumentError, "You must specify at least one column to be used in querying" if columns_list.empty?

            @query_constraints_list = columns_list.map(&:to_s)
          end

          if ::ActiveRecord::VERSION::STRING <= "7.1"
            def query_constraints_list # :nodoc:
              @query_constraints_list ||= if base_class? || primary_key != base_class.primary_key
                                            primary_key if primary_key.is_a?(Array)
                                          else
                                            base_class.query_constraints_list
                                          end
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
