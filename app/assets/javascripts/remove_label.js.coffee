@removeLabel =
  init: ->
    removeLabel.remove 'issue'
    removeLabel.remove 'merge-request'

  remove: (type) ->
    $('.' + type + '-show-labels').on "click", ".label-choice-close", (e) ->
      e.preventDefault()
      label_id = $(this).attr("label_id")
      type = type.replace(/\-/,'_')
      $('#' + type + '_label_ids option[value="' + label_id + '"]').removeAttr("selected")
      $('#' + type + '_label_ids').trigger("change")
      return false

$ ->
  removeLabel.init()
