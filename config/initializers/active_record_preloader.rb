# frozen_string_literal: true

# Some polymorphic associations may refer to an object which is not a subclass of ActiveRecord.
# This patch skips preloading of these associations.
#
# For example, a note's noteable can be an Issue, Merge Request, or Commit, where Commit is
# not a subclass of ActiveRecord. When you run something like:
#
# Note.includes(noteable: :assignees).to_a
#
# This patch allows preloading of issues, merge requests, and their assignees while skipping
# commits.

module ActiveRecord
  module Associations
    class Preloader
      class Association
        class LoaderQuery
          # https://gitlab.com/gitlab-org/gitlab/-/issues/385739
          module HandlePreloadsForDifferentClassesSeparately
            def eql?(other)
              scope.klass == other.scope.klass && super
            end

            def hash
              [scope.klass, association_key_name, scope.table_name, scope.values_for_queries].hash
            end
          end

          prepend HandlePreloadsForDifferentClassesSeparately
        end

        module NonActiveRecordPreloader
          # https://github.com/rails/rails/blob/v7.0.5/activerecord/lib/active_record/associations/preloader/association.rb#L114-L116
          def run?
            return true unless klass < ActiveRecord::Base

            super
          end

          # https://github.com/rails/rails/blob/v7.0.5/activerecord/lib/active_record/associations/preloader/association.rb#L137-L141
          def preloaded_records
            return [] unless klass < ActiveRecord::Base

            super
          end
        end

        prepend NonActiveRecordPreloader
      end

      class Branch
        module NonActiveRecordPreloader
          # https://github.com/rails/rails/blob/v7.0.5/activerecord/lib/active_record/associations/preloader/branch.rb#L37-L45
          def target_classes
            super.delete_if { |klass| !(klass < ActiveRecord::Base) }
          end
        end

        prepend NonActiveRecordPreloader
      end
    end
  end
end
