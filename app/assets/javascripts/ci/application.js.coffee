#= require pager
#= require jquery_nested_form
#= require_tree .

$(document).on 'click', '.assign-all-runner', ->
  $(this).replaceWith('<i class="fa fa-refresh fa-spin"></i> Assign in progress..')

window.unbindEvents = ->
  $(document).unbind('scroll')
  $(document).off('scroll')

document.addEventListener("page:fetch", unbindEvents)
