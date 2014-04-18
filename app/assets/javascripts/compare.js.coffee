class Compare
  constructor: ->
    $("#from, #to").autocomplete({
      source: gon.available_tags,
      minLength: 1
    })

    @comparePathContainer = $('#comparePathContainer')
    @pathSelectInput = $("#paths")

    @pathSelectInput.autocomplete({
      source: gon.available_paths,
      minLength: 1,
      select: (event, ui) =>
        event.preventDefault()
        @addPath(ui.item.value)
    })
    .keypress((event) =>
      if event.which == 13 and @pathSelectInput.val()
        event.preventDefault()
        event.stopPropagation()
        @pathSelectInput.autocomplete("close");
        @addPath()
    )

    @comparePathContainer.on('click', '.icon-remove', () ->
      $(@).parent().remove()
    )

    disableButtonIfEmptyField('#to', '.commits-compare-btn');

  addPath: (pathValue)->
    pathValue ||= @pathSelectInput.val()

    if @newPath(pathValue)
      input = $(gon.path_template)
      input.find('input').val(pathValue)
      @comparePathContainer.append(input)

    @pathSelectInput.val('')

  newPath: (value)->
    @comparePathContainer.find("input[value='#{value}']").length == 0


@Compare = Compare
