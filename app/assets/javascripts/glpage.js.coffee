window.GlPage = {
  pages: {}
  new: (name) ->
    @pages[name] = {
      instances: {}
      events: []

      use: (args...) ->
        if args.length > 1
          for className in args
            @instances[className] = new className()
        else if args.length is 1
          @instances[args[0]] = new args[0]()

      delegate: (targetsObj) ->
        (e, data) ->
          $currentTarget = $(e.currentTarget)
          $target = $(e.target)

          for selector, callback of targetsObj
            children = $currentTarget.find(selector)
            if !e.isPropagationStopped() && children.length
              data = {} if not data
              e.currentTarget = data.el = children[0]
              callback.apply(e.currentTarget, [e, data])

      triggerEventAlias: (targetEvent) ->
        (e, data) ->
          $(e.target).trigger targetEvent, data
          return

      get: (name) ->
        @instances[name]

      trigger: (selector, eventType, data) ->
        $element = type = data = event = defaultFunc = undefined

        $element = selector
        event = eventType

        data = {} if not data

        if event.defaultCallback
          defaultFunc = event.defaultCallback
          event = $.Event(event.type)

        type = event.type or event

        $element.trigger((event or type), data)

        if defaultFunc and not event.isDefaultPrevented()
          defaultFunc.call($element, event, data)

      on: (selector, eventType, handler) ->
        $el = $(selector)
        callback = undefined
        type = eventType

        if typeof handler is 'string'
          callback = @triggerEventAlias(handler)
        else if typeof handler is 'object'
          callback = @delegate(handler)
        else
          callback = handler

        if typeof callback isnt 'function'
          throw new Error 'Unable to register event #{type}, handler should be a function, object or string'

        @events.push({
          el: $el,
          type: eventType,
          handler: callback
        })

        $el.on(type, callback)

      off: (args...) ->
        $el = type = callback = undefined
        lastArgIndex = args.length - 1

        if args.length is 0
          @events.forEach((event) =>
            $el = $(event.el)
            $el.off(event.type, event.callback)
          )

        if typeof args[lastArgIndex] is 'function'
          callback = args[lastArgIndex]
          lastArgIndex -= 1

        if lastArgIndex == 1
          $el = $(args[0])
          type = args[1]

        if callback
          $el.off(type, callback)
        else
          $el.off(type)

      remove: (name) ->
        delete @instances[name]

      removeAll: ->
        @instances = {}
        @off()
        @events = []
        return
    }

  get: (name) ->
    @pages[name]
}