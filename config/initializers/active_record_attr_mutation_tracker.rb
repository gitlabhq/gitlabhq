# Remove once https://github.com/rails/rails/pull/32498
# is released on a 5.1.x rails version.
# Commit on 5-1-stable branch: https://github.com/rails/rails/commit/6ef736625eddf6700f2e67f7849c79c92381abee

module ActiveRecord
  class AttributeMutationTracker
    def changes
      attr_names.each_with_object({}.with_indifferent_access) do |attr_name, result|
        change = change_to_attribute(attr_name)
        if change
          result.merge!(attr_name => change)
        end
      end
    end
  end
end
