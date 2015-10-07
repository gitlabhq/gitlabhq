# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
# WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
# GO AFTER THE REQUIRES BELOW.
#
#= require pager
#= require jquery_nested_form
#= require_tree .
#
$(document).on 'click', '.edit-runner-link', (event) ->
  event.preventDefault()

  descr = $(this).closest('.runner-description').first()
  descr.addClass('hide')
  form = descr.next('.runner-description-form')
  descrInput = form.find('input.description')
  originalValue = descrInput.val()
  form.removeClass('hide')
  form.find('.cancel').on 'click', (event) ->
    event.preventDefault()

    form.addClass('hide')
    descrInput.val(originalValue)
    descr.removeClass('hide')

$(document).on 'click', '.assign-all-runner', ->
  $(this).replaceWith('<i class="fa fa-refresh fa-spin"></i> Assign in progress..')

window.unbindEvents = ->
  $(document).unbind('scroll')
  $(document).off('scroll')

document.addEventListener("page:fetch", unbindEvents)
