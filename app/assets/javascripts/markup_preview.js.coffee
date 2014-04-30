class MarkupPreview

  ###
  Sets up markup preview on all `.js-gfm-input` elements inside given container.

  There can be only one js-gfm-input per form.
  ###
  constructor: (container = $(document)) ->
    GitLab.GfmAutoComplete.setup()
    @cleanBinding(container)
    @addBinding(container)
    input = container.find(".js-gfm-input")
    disableButtonIfEmptyField(input, ".js-gfm-preview-button")
    input.trigger("input")

  addBinding: (container) ->
    $(container).on("click", ".js-gfm-preview-button", @preview)

  cleanBinding: (container) ->
    $(container).off("click", ".js-gfm-preview-button")

  ###
  Shows the markup preview.

  Lets the server render GFM into Html and displays it.

  Uses the Toggler behavior to toggle preview/edit views/buttons
  ###
  preview: (e) ->
    e.preventDefault()
    form = $(@).closest("form")
    preview = form.find(".js-gfm-preview")
    text = form.find(".js-gfm-input").val()
    preview.text "Loading..."
    $.post($(@).data("url"),
      text: text,
      header_anchors: $(@).data("header-anchors")
    ).done (previewData) ->
      preview.html previewData

@MarkupPreview = MarkupPreview
