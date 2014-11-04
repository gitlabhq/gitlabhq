class @EditTreeView
  constructor: ->
    new_branch_name = $('#new_branch_name')
    on_my_fork_group = $('#on_my_fork_group')
    create_merge_request = $('#create_merge_request')
    on_my_fork = $('#on_my_fork')
    source_project = $('#source_project')
    source_branch = $('#source_branch')

    on_change_create_mr = ->
      if create_merge_request.prop('checked')
        on_my_fork_group.show()
        new_branch_name.prop('disabled', false)
        source_branch.addClass('on')
        if on_my_fork.prop('checked')
          source_project.removeClass('on')
      else
        on_my_fork_group.hide()
        new_branch_name.prop('disabled', true)
        source_project.addClass('on')
        source_branch.removeClass('on')
    create_merge_request.on('change', on_change_create_mr)

    on_change_on_my_fork = ->
      source_project.toggleClass('on')
      if on_my_fork.prop('checked')
        if new_branch_name.val() == gon.new_branch_name_this
          new_branch_name.val(gon.new_branch_name_fork)
      else
        if new_branch_name.val() == gon.new_branch_name_fork
          new_branch_name.val(gon.new_branch_name_this)
    on_my_fork.on('change', on_change_on_my_fork)

    # Run in case the browser cached the checkbox state on refresh
    # to fix the state of dependent fields.
    on_change_create_mr()
