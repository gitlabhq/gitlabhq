class @ProtectedBranchSelect
  constructor: (currentProject) ->
    $('.dropdown-footer').hide();
    @dropdown = $('.js-protected-branch-select').glDropdown(
      data: @getProtectedBranches
      filterable: true
      remote: false
      search:
        fields: ['title']
      selectable: true
      toggleLabel: (selected) -> if (selected and 'id' of selected) then selected.title else 'Protected Branch'
      fieldName: 'protected_branch[name]'
      text: (protected_branch) -> _.escape(protected_branch.title)
      id: (protected_branch) -> _.escape(protected_branch.id)
      onFilter: @toggleCreateNewButton
      clicked: () -> $('.protect-branch-btn').attr('disabled', false)
    )

    $('.create-new-protected-branch').on 'click', (event) =>
      # Refresh the dropdown's data, which ends up calling `getProtectedBranches`
      @dropdown.data('glDropdown').remote.execute()
      @dropdown.data('glDropdown').selectRowAtIndex(event, 0)

  getProtectedBranches: (term, callback) =>
    if @selectedBranch
      callback(gon.open_branches.concat(@selectedBranch))
    else
      callback(gon.open_branches)

  toggleCreateNewButton: (branchName) =>
    @selectedBranch = { title: branchName, id: branchName, text: branchName }

    if branchName is ''
      $('.protected-branch-select-footer-list').addClass('hidden')
      $('.dropdown-footer').hide();
    else
      $('.create-new-protected-branch').text("Create Protected Branch: #{branchName}")
      $('.protected-branch-select-footer-list').removeClass('hidden')
      $('.dropdown-footer').show();

