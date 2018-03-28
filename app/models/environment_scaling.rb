class EnvironmentScaling < ActiveRecord::Base
  belongs_to :environment, required: true

  validates :production_replicas, presence: true

  def available?
    environment.project.variables.find_by(key: 'PRODUCTION_REPLICAS').nil?
  end

  def predefined_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'PRODUCTION_REPLICAS', value: production_replicas)
    end
  end
end
