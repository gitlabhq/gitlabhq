# frozen_string_literal: true

class AddValidRunnerRegistrars < ActiveRecord::Migration[6.0]
  def change
    add_column :application_settings, :valid_runner_registrars, :string, array: true, default: %w(project group)
  end
end
