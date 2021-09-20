# frozen_string_literal: true

# This parameter describes a virtual context to indicate
# table affinity to other tables.
#
# Table affinity limits cross-joins, cross-modifications,
# foreign keys and validates relationship between tables
#
# By default it is undefined
ActiveRecord::Base.class_attribute :gitlab_schema, default: nil
