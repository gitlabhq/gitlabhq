# frozen_string_literal: true

class AddDefaultAndFreePlans < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class Plan < ApplicationRecord
  end

  def up
    plan_names.each do |plan_name|
      Plan.create_with(title: plan_name.titleize).find_or_create_by(name: plan_name)
    end
  end

  def down
    Plan.where(name: plan_names).delete_all
  end

  private

  def plan_names
    [
      ('free' if Gitlab.com?),
      'default'
    ].compact
  end
end
