# frozen_string_literal: true

module Organizations
  module Release
    # A single release stage in the Organizations platform release process.
    # Each stage maps to exactly one shared stage flag.
    #
    # The terminal "Stable" state -- where the flag and its guards are removed
    # and the feature is permanently on -- is not modelled here: reaching it
    # means deleting the flag's registry entry, not setting a stage. See the
    # release process doc.
    Stage = Struct.new(:key, :flag, :label, :audience, :description, keyword_init: true)

    class Stage
      # The LA (Limited Availability) stages roll the flag out to an
      # increasing share of GitLab.com. They are identical apart from the
      # percentage, so build them from it.
      LA_PERCENTAGES = [25, 50, 75, 100].freeze

      la_stages = LA_PERCENTAGES.map do |percentage|
        new(
          key: :"la_#{percentage}",
          flag: :"org_stage_la_#{percentage}",
          label: "LA (#{percentage}%)",
          audience: percentage == 100 ? 'All GitLab.com customers' : "Customers, #{percentage}% rollout",
          description: "Trusted as working. Rolled out to #{percentage}% of GitLab.com."
        )
      end

      # The ordered catalog of stages. Stages progress in one direction, and this
      # order defines that progression for both display and rollback validation.
      ALL = [
        new(
          key: :experimental,
          flag: :org_stage_experimental,
          label: 'Experimental',
          audience: 'Organizations team and selected peers',
          description: 'In flux. Being designed and built. No stability contract.'
        ),
        new(
          key: :beta,
          flag: :org_stage_beta,
          label: 'Beta',
          audience: 'GitLab Team Members and opted-in customers',
          description: 'Ready for real world use. No SLA. May change.'
        ),
        *la_stages,
        new(
          key: :ga,
          flag: :org_stage_ga,
          label: 'GA',
          audience: 'Everyone',
          description: 'Generally available on all platforms. Flag retained as a handbrake (inert on GitLab Dedicated).'
        )
      ].freeze

      BY_KEY = ALL.index_by(&:key).freeze
    end
  end
end
