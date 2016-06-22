class @PathLocks
  @init: (url, path) ->
    $('a.path-lock').on 'click',  ->
      $lockBtn = $(this)
      currentState = $lockBtn.data('state')
      toggleAction = if currentState is 'lock' then 'unlock' else 'lock'
      $.post url, {
        path: path
      }, ->
        Turbolinks.visit(location.href)
