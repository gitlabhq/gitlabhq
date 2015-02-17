class @Autosave
  constructor: (field, key) ->
    @field = field

    key = key.join("/") if key.join?
    @key = "autosave/#{key}"

    @field.data "autosave", this

    @restore()

    @field.on "input", => @save()

  restore: ->
    return unless window.localStorage?

    text = window.localStorage.getItem @key
    @field.val text if text?.length > 0
    @field.trigger "input"    

  save: ->
    return unless window.localStorage?

    text = @field.val()
    if text?.length > 0
      window.localStorage.setItem @key, text
    else
      @reset()

  reset: ->
    return unless window.localStorage?

    window.localStorage.removeItem @key