class @ConfirmDangerModal
  constructor: (form, text) ->
    @form = form
    $('.js-confirm-text').text(text || '')
    $('.js-confirm-danger-input').val('')
    $('#modal-confirm-danger').modal('show')
    project_path = $('.js-confirm-danger-match').text()
    submit = $('.js-confirm-danger-submit')
    submit.disable()

    $('.js-confirm-danger-input').off 'input'
    $('.js-confirm-danger-input').on 'input', ->
      if rstrip($(@).val()) is project_path
        submit.enable()
      else
        submit.disable()

    $('.js-confirm-danger-submit').off 'click'
    $('.js-confirm-danger-submit').on 'click', =>
      @form.submit()
