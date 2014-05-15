#
# * Filter merge requests
#
@merge_requestsPage = ->
  $('#assignee_id').select2()
  $('#milestone_id').select2()
  $('#milestone_id, #assignee_id').on 'change', ->
    $(this).closest('form').submit()
