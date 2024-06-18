# frozen_string_literal: true

class FeatureFlagStrategiesValidator < ActiveModel::EachValidator
  STRATEGY_DEFAULT = 'default'
  STRATEGY_GRADUALROLLOUTUSERID = 'gradualRolloutUserId'
  STRATEGY_USERWITHID = 'userWithId'
  # Order key names alphabetically
  STRATEGIES = {
    STRATEGY_DEFAULT => [].freeze,
    STRATEGY_GRADUALROLLOUTUSERID => %w[groupId percentage].freeze,
    STRATEGY_USERWITHID => ['userIds'].freeze
  }.freeze
  USERID_MAX_LENGTH = 256

  def validate_each(record, attribute, value)
    return unless value

    if value.is_a?(Array) && value.all?(Hash)
      value.each do |strategy|
        strategy_validations(record, attribute, strategy)
      end
    else
      error(record, attribute, 'must be an array of strategy hashes')
    end
  end

  private

  def strategy_validations(record, attribute, strategy)
    validate_name(record, attribute, strategy) &&
      validate_parameters_type(record, attribute, strategy) &&
      validate_parameters_keys(record, attribute, strategy) &&
      validate_parameters_values(record, attribute, strategy)
  end

  def validate_name(record, attribute, strategy)
    STRATEGIES.key?(strategy['name']) || error(record, attribute, 'strategy name is invalid')
  end

  def validate_parameters_type(record, attribute, strategy)
    strategy['parameters'].is_a?(Hash) || error(record, attribute, 'parameters are invalid')
  end

  def validate_parameters_keys(record, attribute, strategy)
    name, parameters = strategy.values_at('name', 'parameters')
    actual_keys = parameters.keys.sort
    expected_keys = STRATEGIES[name]
    expected_keys == actual_keys || error(record, attribute, 'parameters are invalid')
  end

  def validate_parameters_values(record, attribute, strategy)
    case strategy['name']
    when STRATEGY_GRADUALROLLOUTUSERID
      gradual_rollout_user_id_parameters_validation(record, attribute, strategy)
    when STRATEGY_USERWITHID
      user_with_id_parameters_validation(record, attribute, strategy)
    end
  end

  def gradual_rollout_user_id_parameters_validation(record, attribute, strategy)
    percentage = strategy.dig('parameters', 'percentage')
    group_id = strategy.dig('parameters', 'groupId')

    unless percentage.is_a?(String) && percentage.match(/\A[1-9]?[0-9]\z|\A100\z/)
      error(record, attribute, 'percentage must be a string between 0 and 100 inclusive')
    end

    unless group_id.is_a?(String) && group_id.match(/\A[a-z]{1,32}\z/)
      error(record, attribute, 'groupId parameter is invalid')
    end
  end

  def user_with_id_parameters_validation(record, attribute, strategy)
    user_ids = strategy.dig('parameters', 'userIds')
    unless user_ids.is_a?(String) && !user_ids.match(/[\n\r\t]|,,/) && valid_ids?(user_ids.split(","))
      error(record, attribute, "userIds must be a string of unique comma separated values each #{USERID_MAX_LENGTH} characters or less")
    end
  end

  def valid_ids?(user_ids)
    user_ids.uniq.length == user_ids.length &&
      user_ids.all? { |id| valid_id?(id) }
  end

  def valid_id?(user_id)
    user_id.present? &&
      user_id.strip == user_id &&
      user_id.length <= USERID_MAX_LENGTH
  end

  def error(record, attribute, msg)
    record.errors.add(attribute, msg)
    false
  end
end
