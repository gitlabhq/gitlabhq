# frozen_string_literal: true

module Admin
  class SetFeatureFlagService
    UnknownOperationError = Class.new(StandardError)

    def initialize(feature_flag_name:, params:)
      @name = feature_flag_name
      @target = Feature::Target.new(params)
      @params = params
      @force = params[:force]
    end

    def execute
      unless force
        error = validate_feature_flag_name
        return ServiceResponse.error(message: error, reason: :invalid_feature_flag) if error
      end

      if target.gate_specified?
        update_targets
      else
        update_global
      end

      feature_flag = Feature.get(name) # rubocop:disable Gitlab/AvoidFeatureGet

      ServiceResponse.success(payload: { feature_flag: feature_flag })
    rescue Feature::InvalidOperation => e
      ServiceResponse.error(message: e.message, reason: :illegal_operation)
    rescue UnknownOperationError => e
      ServiceResponse.error(message: e.message, reason: :illegal_operation)
    rescue Feature::Target::UnknownTargetError => e
      ServiceResponse.error(message: e.message, reason: :actor_not_found)
    end

    private

    attr_reader :name, :params, :target, :force

    # Note: the if expressions in `update_targets` and `update_global` are order dependant.
    def update_targets
      target.targets.each do |target|
        if enable?
          enable(target)
        elsif disable?
          Feature.disable(name, target)
        elsif opt_out?
          Feature.opt_out(name, target)
        elsif remove_opt_out?
          remove_opt_out(target)
        else
          raise UnknownOperationError, "Cannot set '#{name}' to #{value.inspect} for #{target}"
        end
      end
    end

    def update_global
      if enable?
        Feature.enable(name)
      elsif disable?
        Feature.disable(name)
      elsif percentage_of_actors?
        Feature.enable_percentage_of_actors(name, percentage)
      # Deprecated in favor of Feature.enabled?(name, :instance) + Feature.enable_percentage_of_actors(name, percentage)
      elsif percentage_of_time?
        Feature.enable_percentage_of_time(name, percentage)
      else
        msg = if key.present?
                "Cannot set '#{name}' (#{key.inspect}) to #{value.inspect}"
              else
                "Cannot set '#{name}' to #{value.inspect}"
              end

        raise UnknownOperationError, msg
      end
    end

    def remove_opt_out(target)
      raise Feature::InvalidOperation, "No opt-out exists for #{target}" unless Feature.opted_out?(name, target)

      Feature.remove_opt_out(name, target)
    end

    def enable(target)
      if Feature.opted_out?(name, target)
        target_name = target.respond_to?(:to_reference) ? target.to_reference : target.to_s
        raise Feature::InvalidOperation, "Opt-out exists for #{target_name} - remove opt-out before enabling"
      end

      Feature.enable(name, target)
    end

    def value
      params[:value]
    end

    def key
      params[:key]
    end

    def numeric_value?
      params[:value].match?(/^\d+(\.\d+)?$/)
    end

    def percentage
      raise UnknownOperationError, "Not a percentage" unless numeric_value?

      value.to_f
    end

    def percentage_of_actors?
      key == 'percentage_of_actors'
    end

    def percentage_of_time?
      return true if key == 'percentage_of_time'
      return numeric_value? if key.nil?

      false
    end

    # Note: `key` is NOT considered - setting to a percentage to 0 is the same as disabling.
    def disable?
      value.in?(%w[0 0.0 false])
    end

    # Note: `key` is NOT considered - setting to a percentage to 100 is the same
    def enable?
      value.in?(%w[100 100.0 true])
    end

    def opt_out?
      value == 'opt_out'
    end

    def remove_opt_out?
      value == 'remove_opt_out'
    end

    def validate_feature_flag_name
      ## Overridden in EE
    end
  end
end

Admin::SetFeatureFlagService.prepend_mod
