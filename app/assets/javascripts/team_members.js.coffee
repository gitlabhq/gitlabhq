class TeamMembers
  constructor: ->
    $('.team-members .project-access-select').on "change", ->
      $(this.form).submit()

@TeamMembers = TeamMembers
