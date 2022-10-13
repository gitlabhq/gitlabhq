# frozen_string_literal: true

module Admin
  class SetFeatureFlagService
    def initialize(feature_flag_name:, params:)
      @name = feature_flag_name
      @params = params
    end

    def execute
      unless params[:force]
        error = validate_feature_flag_name
        return ServiceResponse.error(message: error, reason: :invalid_feature_flag) if error
      end

      flag_target = Feature::Target.new(params)
      value = gate_value(params)

      case value
      when true
        enable!(flag_target)
      when false
        disable!(flag_target)
      else
        enable_partially!(value, params)
      end

      feature_flag = Feature.get(name) # rubocop:disable Gitlab/AvoidFeatureGet

      ServiceResponse.success(payload: { feature_flag: feature_flag })
    rescue Feature::Target::UnknowTargetError => e
      ServiceResponse.error(message: e.message, reason: :actor_not_found)
    end

    private

    attr_reader :name, :params

    def enable!(flag_target)
      if flag_target.gate_specified?
        flag_target.targets.each { |target| Feature.enable(name, target) }
      else
        Feature.enable(name)
      end
    end

    def disable!(flag_target)
      if flag_target.gate_specified?
        flag_target.targets.each { |target| Feature.disable(name, target) }
      else
        Feature.disable(name)
      end
    end

    def enable_partially!(value, params)
      if params[:key] == 'percentage_of_actors'
        Feature.enable_percentage_of_actors(name, value)
      else
        Feature.enable_percentage_of_time(name, value)
      end
    end

    def validate_feature_flag_name
      # overridden in EE
    end

    def gate_value(params)
      case params[:value]
      when 'true'
        true
      when '0', 'false'
        false
      else
        # https://github.com/jnunemaker/flipper/blob/master/lib/flipper/typecast.rb#L47
        if params[:value].to_s.include?('.')
          params[:value].to_f
        else
          params[:value].to_i
        end
      end
    end
  end
end

Admin::SetFeatureFlagService.prepend_mod
