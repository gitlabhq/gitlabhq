class @PathLocks
  @init: (url, path) ->
    $('.path-lock').on 'click',  ->
      $lockBtn = $(this)
      currentState = $lockBtn.data('state')
      toggleAction = if currentState is 'lock' then 'unlock' else 'lock'
      $.post url, {
        path: path
      }, ->
        $lockBtn.text(gl.utils.capitalize(toggleAction))
        $lockBtn.data('state', toggleAction)
