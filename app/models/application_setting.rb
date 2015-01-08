class ApplicationSetting < ActiveRecord::Base
  def self.current
    ApplicationSetting.last
  end
end
