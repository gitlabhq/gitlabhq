class EditTreeView
  constructor: ->
    new_branch_name = $('#new_branch_name')
    new_branch_name_group = $('#new_branch_name_group')
    create_merge_request = $('#create_merge_request')
    on_my_fork = $('#on_my_fork')
    on_change_create_mr = ->
      if create_merge_request.prop('checked')
        new_branch_name_group.show()
        new_branch_name.prop('disabled', false)
      else
        new_branch_name_group.hide()
        new_branch_name.prop('disabled', true)
    on_change_on_my_fork = ->
      if on_my_fork.prop('checked')
        if new_branch_name.val() == gon.new_branch_name_this
          new_branch_name.val(gon.new_branch_name_fork)
      else
        if new_branch_name.val() == gon.new_branch_name_fork
          new_branch_name.val(gon.new_branch_name_this)
    create_merge_request.on('change', on_change_create_mr)
    on_my_fork.on('change', on_change_on_my_fork)
    # Run it in case the browser cached the checkbox value and overrode checked.
    on_change_create_mr()
    on_change_on_my_fork()

@EditTreeView = EditTreeView
