class EnvironmentScaling < ActiveRecord::Base
  belongs_to :environment, required: true
end
