class @ProjectMembers

	constructor: ->
		@addMemberButton = $('#new_project_member input[type="submit"].btn-create')
		@addMemberInput = $('#new_project_member #user_ids')
		
		$('li.project_member').bind 'ajax:success', ->
			$(this).fadeOut()
			
		@cleanBinding()
		@addBinding()
	
	addBinding: ->
    $(document).on 'change', @addMemberInput, @toggleAddButton

  cleanBinding: ->
    $(document).off 'change', @addMemberInput
	
	toggleAddButton: =>
		_enable = !!@addMemberInput.val()
		if _enable is undefined then @addMemberButton.toggle() else (if _enable then @addMemberButton.enable() else @addMemberButton.disable())
