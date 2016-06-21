class @LabelManager
  errorMessage: 'Unable to update label prioritization at this time'

  constructor: (opts = {}) ->
    # Defaults
    {
      @togglePriorityButton = $('.js-toggle-priority')
      @prioritizedLabels = $('.js-prioritized-labels')
      @otherLabels = $('.js-other-labels')
    } = opts

    @prioritizedLabels.sortable(
      items: 'li'
      placeholder: 'list-placeholder'
      axis: 'y'
      update: @onPrioritySortUpdate.bind(@)
    )

    @bindEvents()

  bindEvents: ->
    @togglePriorityButton.on 'click', @, @onTogglePriorityClick

  onTogglePriorityClick: (e) ->
    e.preventDefault()
    _this = e.data
    $btn = $(e.currentTarget)
    $label = $("##{$btn.data('domId')}")
    action = if $btn.parents('.js-prioritized-labels').length then 'remove' else 'add'

    # Make sure tooltip will hide
    $tooltip = $ "##{$btn.find('.has-tooltip:visible').attr('aria-describedby')}"
    $tooltip.tooltip 'destroy'

    _this.toggleLabelPriority($label, action)

  toggleLabelPriority: ($label, action, persistState = true) ->
    _this = @
    url = $label.find('.js-toggle-priority').data 'url'

    $target = @prioritizedLabels
    $from = @otherLabels

    # Optimistic update
    if action is 'remove'
      $target = @otherLabels
      $from = @prioritizedLabels

    if $from.find('li').length is 1
      $from.find('.empty-message').removeClass('hidden')

    if not $target.find('li').length
      $target.find('.empty-message').addClass('hidden')

    $label.detach().appendTo($target)

    # Return if we are not persisting state
    return unless persistState

    if action is 'remove'
      xhr = $.ajax url: url, type: 'DELETE'

      # Restore empty message
      $from.find('.empty-message').removeClass('hidden') unless $from.find('li').length
    else
      xhr = @savePrioritySort($label, action)

    xhr.fail @rollbackLabelPosition.bind(@, $label, action)

  onPrioritySortUpdate: ->
    xhr = @savePrioritySort()

    xhr.fail ->
      new Flash(@errorMessage, 'alert')

  savePrioritySort: () ->
    $.post
      url: @prioritizedLabels.data('url')
      data:
        label_ids: @getSortedLabelsIds()

  rollbackLabelPosition: ($label, originalAction)->
    action = if originalAction is 'remove' then 'add' else 'remove'
    @toggleLabelPriority($label, action, false)

    new Flash(@errorMessage, 'alert')

  getSortedLabelsIds: ->
    sortedIds = []
    @prioritizedLabels.find('li').each ->
      sortedIds.push $(@).data 'id'
    sortedIds
