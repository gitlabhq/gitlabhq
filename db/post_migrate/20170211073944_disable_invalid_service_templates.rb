class DisableInvalidServiceTemplates < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  class Service < ActiveRecord::Base
    self.inheritance_column = nil
  end

  def up
    Service.where(template: true, active: true).each do |template|
      template.update(active: false) unless template.valid?
    end
  end
end
