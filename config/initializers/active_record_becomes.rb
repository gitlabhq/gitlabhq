# rubocop:disable Gitlab/ModuleWithInstanceVariables

# Remove once https://github.com/rails/rails/issues/32867
# is released on a 5.1.x rails version.
# Commit on 5-1-stable branch: https://github.com/rails/rails/commit/44f0df3f3980ba3aeca956839e1948b246ff34fe

module ActiveRecord
  module AttributeMethods
    module Dirty
      def attributes_in_database
        mutations_from_database.changed_values
      end
    end
  end

  module Persistence
    def becomes(klass)
      became = klass.new
      became.instance_variable_set("@attributes", @attributes)
      became.instance_variable_set("@mutation_tracker", @mutation_tracker ||= nil)
      became.instance_variable_set("@mutations_from_database", @mutations_from_database ||= nil)
      became.instance_variable_set("@changed_attributes", attributes_changed_by_setter)
      became.instance_variable_set("@new_record", new_record?)
      became.instance_variable_set("@destroyed", destroyed?)
      became.errors.copy!(errors)
      became
    end
  end
end
