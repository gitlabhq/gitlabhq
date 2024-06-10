# frozen_string_literal: true

module Ci
  class UpdatePendingBuildService
    VALID_PARAMS = %i[instance_runners_enabled namespace_id namespace_traversal_ids].freeze

    InvalidParamsError = Class.new(StandardError)
    InvalidModelError = Class.new(StandardError)

    def initialize(model, update_params)
      @model = model
      @update_params = update_params.symbolize_keys

      validations!
    end

    def execute
      @model.pending_builds.each_batch do |relation|
        relation.update_all(@update_params)
      end
    end

    private

    def validations!
      validate_model! && validate_params!
    end

    def validate_model!
      raise InvalidModelError unless @model.is_a?(::Project) || @model.is_a?(::Group)

      true
    end

    def validate_params!
      extra_params = @update_params.keys - VALID_PARAMS

      raise InvalidParamsError, "Invalid params: #{extra_params.join(', ')}" if extra_params.any?

      true
    end
  end
end
