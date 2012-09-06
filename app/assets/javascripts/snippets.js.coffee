$ ->
  $('#snippets-table .snippet').live 'click', (e) ->
    if e.target.nodeName isnt 'A' and e.target.nodeName isnt 'INPUT'
      location.href = $(@).attr 'url'
      e.stopPropagation()
      false
