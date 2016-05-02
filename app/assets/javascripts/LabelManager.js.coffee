class @LabelManager
  constructor: (opts = {}) ->
    # Defaults
    {
      @togglePriorityButton = $('.js-toggle-priority')
      @prioritizedLabels = $('.js-prioritized-labels')
      @otherLabels = $('.js-other-labels')
    } = opts

    @prioritizedLabels.sortable(
      items: 'li'
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
    _this.toggleLabelPriority($label, action)

  toggleLabelPriority: ($label, action, pasive = false) ->
    _this = @
    url = $label.find('.js-toggle-priority').data 'url'

    $target = @prioritizedLabels
    $from = @otherLabels

    # Optimistic update
    if action is 'remove'
      $target = @otherLabels
      $from = @prioritizedLabels

    if $from.find('li').length is 1
      $from.find('.empty-message').show()

    if not $target.find('li').length
      $target.find('.empty-message').hide()

    $label.detach().appendTo($target)

    # Return if we are not persisting state
    return if pasive

    xhr = $.post url

    # If request fails, put label back to Other labels group
    xhr.fail ->
      _this.toggleLabelPriority($label, 'remove', true)

      # Show a message
      new Flash('Unable to update label prioritization at this time' , 'alert')

  onPrioritySortUpdate: ->
    @savePrioritySort()

  savePrioritySort: ->
    xhr = $.post
            url: @prioritizedLabels.data('url')
            data:
              label_ids: @getSortedLabelsIds()

    xhr.done ->
      console.log 'done'

    xhr.fail ->
      console.log 'fail'

  getSortedLabelsIds: ->
    sortedIds = []
    @prioritizedLabels.find('li').each ->
      sortedIds.push $(@).data 'id'
    sortedIds