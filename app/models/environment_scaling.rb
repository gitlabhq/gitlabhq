class EnvironmentScaling < ActiveRecord::Base
  belongs_to :environment, required: true

  validates :replicas, numericality: { only_integer: true }, presence: true

  def predefined_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: "#{environment.variable_prefix}_REPLICAS", value: replicas)
    end
  end
end
