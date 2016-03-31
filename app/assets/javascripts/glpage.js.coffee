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
        generated
        
      get: (name) ->
        @instances[name].instance
      
      on: (el, args...) ->
        $el = $(el)
        @events.push({
          el: el,
          args: args
        })
        $el.on.apply($el, args)

      off: (el, args...) ->
        $el = $(el)
        $el.off.apply($el, args)
      
      allOff: ->
        @events.forEach((event) =>
          $el = $(event.el)
          $el.off.apply($el, event.args)
        )

      remove: (name) ->
        delete @instances[name]
      
      removeAll: ->
        @instances = {}
        @allOff()
        @events = []
        return
    }
}