# This is the same as DisableInvalidServiceTemplates. Later migrations may have
# inadvertently enabled some invalid templates again.
#
class DisableInvalidServiceTemplates2 < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  unless defined?(Service)
    class Service < ActiveRecord::Base
      self.inheritance_column = nil
    end
  end

  def up
    Service.where(template: true, active: true).each do |template|
      template.update(active: false) unless template.valid?
    end
  end
end
