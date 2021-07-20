# frozen_string_literal: true

class RemoveNotNullConstraintFromTerms < ActiveRecord::Migration[6.1]
  def up
    change_column_null :application_setting_terms, :terms, true
  end

  def down
    change_column_null :application_setting_terms, :terms, false
  end
end
