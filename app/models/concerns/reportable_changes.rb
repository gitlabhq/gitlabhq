# frozen_string_literal: true

# == ReportableChanges concern
#
# Keeps changes between the values of attributes when the object is loaded
# from persistence and all subsequent saves. This can be useful where there
# are multiple save operations on an object in a given request context and
# final hooks might need access to the cumulative delta, not just that of the
# most recent save.
#
# Used by Issuable.
#
module ReportableChanges
  extend ActiveSupport::Concern

  def as_json(options = {})
    options[:except] = [*options[:except], "reportable_changes"]
    super(options)
  end

  # Maintains a hash of cumulative changes to attributes between when the object
  # was loaded from persistence and its most recent save.
  #
  # This is called by ActiveRecord (and other implementations of
  # ActiveModel::Dirty) once attribute changes are persisted.
  def changes_applied
    super.tap do
      previous_changes.each do |attr, (previous, current)|
        if reportable_changes_store.include?(attr)
          reportable_changes_store[attr][1] = current
        else
          reportable_changes_store[attr] = [previous, current]
        end
      end
    end
  end

  # Returns a hash of attributes that were changed between when the object was
  # initially loaded from persistence (or newly created) and its most recent
  # save. This is in constrast to ActiveModel::Dirty#previous_changes which
  # resets the change state after every save.
  #
  #   person = Person.find_by_name("bob")
  #   person.name # => "bob"
  #
  #   person.name = "robert"
  #   person.save
  #   person.previous_changes   # => {"name" => ["bob", "robert"]}
  #   person.reportable_changes # => {"name" => ["bob", "robert"]}
  #
  #   person.title = "mr"
  #   person.save
  #   person.previous_changes   # => {"title" => [nil, "mr"]}
  #   person.reportable_changes # => {"name" => ["bob", "robert"], "title" => [nil, "mr"]}
  #
  #   person.name = "rob"
  #   person.save
  #   person.previous_changes   # => {"name" => ["robert", "rob"]}
  #   person.reportable_changes # => {"name" => ["bob", "rob"], "title" => [nil, "mr"]}
  def reportable_changes
    reportable_changes_store.clone
  end

  # Reset the reportable changes only when the record is reloaded from persistence.
  # See ActiveRecord::AttributeMethods::Dirty#reload
  def reload(*)
    super.tap do
      reportable_changes_store.clear
    end
  end

  # Reset the reportable changes when explicitly requested.
  # See ActiveModel::Dirty#clear_changes_information
  def clear_changes_information(*)
    super.tap do
      reportable_changes_store.clear
    end
  end

  private

  def reportable_changes_store
    @reportable_changes_store ||= HashWithIndifferentAccess.new
  end
end
