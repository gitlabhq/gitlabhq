class EnvironmentScaling < ActiveRecord::Base
  belongs_to :environment, required: true

  validates :replicas, numericality: { only_integer: true }, presence: true

  def available?
    if environment.project.group
      return false unless environment.project.group.variables.where(key: incompatible_variables).empty?
    end

    environment.project.variables.where(key: incompatible_variables).empty?
  end

  def predefined_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: "#{environment.ci_name}_REPLICAS", value: replicas)
    end
  end

  private

  def incompatible_variables
    predefined_variables.map { |var| var[:key] }.append("PRODUCTION_REPLICAS")
  end
end
