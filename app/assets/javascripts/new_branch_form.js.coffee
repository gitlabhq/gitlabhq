class @NewBranchForm
  constructor: (form, availableRefs) ->
    @branchNameError = form.find('.js-branch-name-error')
    @name = form.find('.js-branch-name')
    @ref  = form.find('#ref')

    @setupAvailableRefs(availableRefs)
    @setupRestrictions()
    @addBinding()
    @init()

  addBinding: ->
    @name.on 'blur', @validate

  init: ->
    @name.trigger 'blur' if @name.val().length > 0

  setupAvailableRefs: (availableRefs) ->
    @ref.autocomplete
      source: availableRefs,
      minLength: 1

  setupRestrictions: ->
    startsWith = {
      pattern: /^(\/|\.)/g,
      prefix: "can't start with",
      conjunction: "or"
    }

    endsWith = {
      pattern: /(\/|\.|\.lock)$/g,
      prefix: "can't end in",
      conjunction: "or"
    }

    invalid = {
      pattern: /(\s|~|\^|:|\?|\*|\[|\\|\.\.|@\{|\/{2,}){1}/g
      prefix: "can't contain",
      conjunction: ", "
    }

    single = {
      pattern: /^@+$/g
      prefix: "can't be",
      conjunction: "or"
    }

    @restrictions = [startsWith, invalid, endsWith, single]

  validate: =>
    @branchNameError.empty()

    unique = (values, value) ->
      values.push(value) unless value in values
      values

    formatter = (values, restriction) ->
      formatted = values.map (value) ->
        switch
          when /\s/.test value then 'spaces'
          when /\/{2,}/g.test value then 'consecutive slashes'
          else "'#{value}'"

      "#{restriction.prefix} #{formatted.join(restriction.conjunction)}"

    validator = (errors, restriction) =>
      matched = @name.val().match(restriction.pattern)

      if matched
        errors.concat formatter(matched.reduce(unique, []), restriction)
      else
        errors

    errors = @restrictions.reduce validator, []

    if errors.length > 0
      errorMessage = $("<span/>").text(errors.join(', '))
      @branchNameError.append(errorMessage)
