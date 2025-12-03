# frozen_string_literal: true

module Pajamas
  class ExperimentBadgeComponentPreview < ViewComponent::Preview
    layout 'lookbook/experiment_badge'

    # Experiment Badge
    # ---
    #
    # Displays a badge indicating a feature is in experiment or beta stage.
    # Includes a popover with information about what the stage means.
    #
    # @param type select {{ Pajamas::ExperimentBadgeComponent::TYPE_OPTIONS }}
    # @param popover_placement select [top, bottom, left, right]
    def default(type: :experiment, popover_placement: 'bottom')
      render Pajamas::ExperimentBadgeComponent.new(
        type: type,
        popover_placement: popover_placement
      )
    end

    # Beta Badge
    # ---
    #
    # Shows a beta badge with information about beta features.
    def beta
      render Pajamas::ExperimentBadgeComponent.new(type: :beta)
    end

    # Experiment Badge
    # ---
    #
    # Shows an experiment badge with information about experimental features.
    def experiment
      render Pajamas::ExperimentBadgeComponent.new(type: :experiment)
    end
  end
end
