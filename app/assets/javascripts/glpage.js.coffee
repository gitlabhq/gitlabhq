window.GlPage = {
  instances: {}
  events: []
  pages: {}
  new: (name) ->
    @pages[name] = {
      instances: {}
      events: []
      use: (instance, name) ->
        generated = name || Math.random().toString(36).substring(7)
        @instances[generated] = {
          instance: instance
          name: generated
        }
        @instances[generated]

      delegate: (targetsObj) ->
        (e, data) ->
          $target = $(e.target)

          for selector, callback of targetsObj
            child = $target.find(selector)
            if !e.isPropagationStopped() && child.length
              data ?= {}
              e.currentTarget = data.el = child[0]
              callback.apply(e.currentTarget, [e, data])

      triggerEventAlias: (targetEvent) ->
        (e, data) ->
          $(e.target).trigger targetEvent, data
          return

      get: (name) ->
        @instances[name].instance

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
          el: el,
          type: eventType,
          handler: callback
        })

        $el.on(type, callback)

      off: (args...) ->
        $el = type = callback = undefined
        lastIndex = args.length - 1

        if args.length is 0
          @events.forEach((event) =>
            $el = $(event.el)
            $el.off(event.type, event.callback)
          )

        if typeof args[lastIndex] is 'function'
          callback = args[lastIndex]
          lastIndex -= 1

        if lastIndex == 1
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
        @allOff()
        @events = []
        return
    }

  get: (name) ->
    @pages[name]
}