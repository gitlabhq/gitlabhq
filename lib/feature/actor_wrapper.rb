# frozen_string_literal: true

module Feature
  class ActorWrapper
    def initialize(model_class, model_id)
      @model_class = model_class
      @model_id = model_id
    end

    def flipper_id
      "#{@model_class.name}:#{@model_id}"
    end
  end
end
