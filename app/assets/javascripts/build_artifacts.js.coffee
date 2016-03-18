class @BuildArtifacts
  constructor: () ->
    @disablePropagation()
    @setupEntryClick()

  disablePropagation: ->
    $('.top-block').on 'click', '.download',  (e) ->
      e.stopPropagation()
    $('.tree-holder').on 'click', 'tr[data-link] a', (e) ->
      e.stopImmediatePropagation()

  setupEntryClick: ->
    $('.tree-holder').on 'click', 'tr[data-link]', (e) ->
      window.location = @dataset.link
