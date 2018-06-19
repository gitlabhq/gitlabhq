class DisableInvalidServiceTemplates < ActiveRecord::Migration
  DOWNTIME = false

  class Service < ApplicationRecord
    self.inheritance_column = nil
  end

  def up
    Service.where(template: true, active: true).each do |template|
      template.update(active: false) unless template.valid?
    end
  end
end
