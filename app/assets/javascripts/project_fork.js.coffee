class @ProjectFork
  constructor: ->
    $('.fork-thumbnail a').on 'click', ->
      $('.fork-namespaces').hide()
      $('.save-project-loader').show()
