# frozen_string_literal: true

# == SafelyChangeColumnDefault concern.
#
# Allows safely changing a column default without downtime.
#
# With Rails +partial_inserts+, an INSERT omits a column whose value equals its in-memory default and relies on the
# database default. While a default is in flux, a process can hold a stale schema-cache default, so relying on the
# database default can write the wrong value -- or a NULL, if the default was dropped from a NOT NULL column. This
# concern forces every listed column into the INSERT so its value is always written explicitly.
# See INC-11487: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/22385
#
# Usage:
#
#   class SomeModel < ApplicationRecord
#     include SafelyChangeColumnDefault
#
#     columns_changing_default :value
#   end
#
#   # Assume a default of 100 for value
#   SomeModel.create! # INSERT INTO some_model (value) VALUES (100)
#   # Without this concern, would be INSERT INTO some_model DEFAULT VALUES, relying on the DB default.
#
# See https://docs.gitlab.com/development/database/avoiding_downtime_in_migrations/#changing-column-defaults for
# the full procedure.
module SafelyChangeColumnDefault
  extend ActiveSupport::Concern

  class_methods do
    # Indicate that one or more columns will have their database default change.
    #
    # By indicating those columns here, this helper prevents a case where explicitly writing the old database default
    # will be mutated to the new database default.
    def columns_changing_default(*columns)
      self.columns_with_changing_default = columns.map(&:to_s)
    end
  end

  included do
    class_attribute :columns_with_changing_default, default: []

    before_create do
      columns_with_changing_default.to_a.each do |attr_name|
        attr = @attributes[attr_name]

        # Force any column whose default is in flux into the INSERT, even when the value was not set by the user, so
        # it is never left to the (possibly stale or dropped) database default.
        attribute_will_change!(attr_name) unless attr.changed?
      end
    end
  end
end
