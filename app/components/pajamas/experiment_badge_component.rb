# frozen_string_literal: true

module Pajamas
  class ExperimentBadgeComponent < Pajamas::Component
    TYPE_OPTIONS = [:experiment, :beta].freeze
    POPOVER_PLACEMENT_OPTIONS = %w[top bottom left right].freeze

    # @param type [Symbol] The type of badge (:experiment or :beta)
    # @param popover_placement [String] The placement of the popover (top, bottom, left, right)
    def initialize(type: :experiment, popover_placement: 'bottom')
      @type = filter_attribute(type.to_sym, TYPE_OPTIONS, default: :experiment)
      @popover_placement = filter_attribute(popover_placement.to_s, POPOVER_PLACEMENT_OPTIONS, default: 'bottom')
    end

    private

    def experiment?
      @type == :experiment
    end

    def badge_text
      experiment? ? s_('ExperimentBadge|Experiment') : s_('BetaBadge|Beta')
    end

    def help_page_url
      anchor = experiment? ? 'experiment' : 'beta'
      "https://docs.gitlab.com/policy/development_stages_support/##{anchor}"
    end

    def popover_title
      experiment? ? s_("ExperimentBadge|What's an experiment?") : s_("BetaBadge|What's a beta?")
    end

    def popover_intro
      if experiment?
        s_("ExperimentBadge|An %{link_start}experiment%{link_end} is not yet production-ready, " \
          "but is released for initial testing and feedback during development.")
      else
        s_("BetaBadge|A %{link_start}beta%{link_end} feature is not yet production-ready, " \
          "but is ready for testing and unlikely to change significantly before it's released.")
      end
    end

    def popover_list_title
      experiment? ? s_('ExperimentBadge|Experiment features:') : s_('BetaBadge|Beta features:')
    end

    def popover_bullets
      if experiment?
        [
          s_('ExperimentBadge|Might be unstable or cause data loss.'),
          s_('ExperimentBadge|Are not supported and might not be documented.'),
          s_('ExperimentBadge|Could be changed or removed at any time.')
        ]
      else
        [
          s_('BetaBadge|Have a low risk of data loss, but might still be unstable.'),
          s_('BetaBadge|Are supported on a commercially-reasonable effort basis.'),
          s_('BetaBadge|Have a near complete user experience.')
        ]
      end
    end
  end
end
