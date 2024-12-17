# frozen_string_literal: true

module MilestonesHelper
  def milestone_header_class(primary, issuables)
    header_color = milestone_header_color(primary: primary)
    header_border = milestone_header_border(issuables)

    "#{header_color} #{header_border} gl-flex"
  end

  def milestone_counter_class(primary)
    primary ? 'gl-text-white' : 'gl-text-subtle'
  end

  private

  def milestone_header_color(primary: false)
    return '' unless primary

    'gl-bg-blue-500 gl-text-white'
  end

  def milestone_header_border(issuables)
    issuables.empty? ? 'gl-border-b-0 gl-rounded-base' : ''
  end
end
