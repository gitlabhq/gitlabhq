# frozen_string_literal: true

# This patch provides a GitLab-specific override of `query_constraints` for
# partitioned models. Rails 7.3+ ships a native `query_constraints` in:
# https://github.com/rails/rails/blob/v8.0.0/activerecord/lib/active_record/persistence.rb#L212
#
# The GitLab version intentionally omits setting `@has_query_constraints` so
# that the standard ActiveRecord `_query_constraints_hash` is not used; instead
# the partitioning layer manages composite-key lookups itself.

if ::ActiveRecord::VERSION::STRING >= "8.1"
  raise 'New version of active-record detected, please remove or update this patch'
end

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module ActiveRecord
  module GitlabPatches
    module Partitioning
      module Base
        if ::ActiveRecord::VERSION::STRING <= "7.2"
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

          if ::ActiveRecord::VERSION::STRING <= "7.2"
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
