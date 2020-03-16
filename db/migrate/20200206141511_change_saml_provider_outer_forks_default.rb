# frozen_string_literal: true

class ChangeSamlProviderOuterForksDefault < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    change_column_null :saml_providers, :prohibited_outer_forks, false
    change_column_default :saml_providers, :prohibited_outer_forks, true
  end

  def down
    change_column_default :saml_providers, :prohibited_outer_forks, false
    change_column_null :saml_providers, :prohibited_outer_forks, true
  end
end
