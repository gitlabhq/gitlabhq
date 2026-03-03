# frozen_string_literal: true

module RapidDiffs
  class MergeRequestAppComponent < ViewComponent::Base
    attr_reader :presenter

    delegate :mr_path, :current_user, to: :presenter

    def initialize(presenter)
      @presenter = presenter
    end
  end
end
