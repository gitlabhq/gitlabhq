@LinesObserver = do ->
  ctrls = []
  return {
    register: (controller) ->
      ctrl = new controller
      ctrl.onunload = ->
        ctrls.splice ctrls.indexOf(ctrl), 1
      ctrls.push
        insrance: ctrl
        controller: controller
    trigger: (resolved, noteId) ->
      ctrls.map (c) ->
        ctrl = new c.controller(resolved, noteId)
        for i in ctrl
          c.instance[i] = ctrl[i]
  }
