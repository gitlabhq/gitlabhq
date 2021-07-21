# frozen_string_literal: true

class ChangeApplicationSettingTermsNotNull < ActiveRecord::Migration[6.1]
  def up
    execute("UPDATE application_setting_terms SET terms = '' WHERE terms IS NULL")
    change_column_null :application_setting_terms, :terms, false
  end

  def down
    change_column_null :application_setting_terms, :terms, true
  end
end
