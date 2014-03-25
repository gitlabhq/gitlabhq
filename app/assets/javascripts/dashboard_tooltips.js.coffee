class DashboardTooltips
  constructor: ->
    @tooltips()

  tooltips: ->
    $('.js-description-tooltip').each(() ->
      $this = $(this)
      if $this.attr('data-title')
        $this.tooltip(
          container: $this
          trigger: "hover"
          placement: "left"
        )
    )

@DashboardTooltips = DashboardTooltips
