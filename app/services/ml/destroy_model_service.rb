# frozen_string_literal: true

module Ml
  class DestroyModelService
    def initialize(model, user)
      @model = model
      @user = user
    end

    def execute
      return unless @model.destroy

      ::Packages::MarkPackagesForDestructionService.new(
        packages: @model.all_packages,
        current_user: @user
      ).execute
    end
  end
end
