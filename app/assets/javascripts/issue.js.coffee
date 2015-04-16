class @Issue
  constructor: ->
    $('.edit-issue.inline-update input[type="submit"]').hide()
    $(".context .inline-update").on "change", "select", ->
      $(this).submit()
    $(".context .inline-update").on "change", "#issue_assignee_id", ->
      $(this).submit()

    if $("a.btn-close").length
      $("li.task-list-item input:checkbox").prop("disabled", false)

    $('.task-list-item input:checkbox').off('change')
    $('.task-list-item input:checkbox').change('issue', updateTaskState)

    $('.issue-details').waitForImages ->
      $('.issuable-affix').affix offset:
        top: ->
          @top = ($('.issuable-affix').offset().top - 70)
        bottom: ->
          @bottom = $('.footer').outerHeight(true)
      $('.issuable-affix').on 'affix.bs.affix', ->
        $(@).width($(@).outerWidth())
      .on 'affixed-top.bs.affix affixed-bottom.bs.affix', ->
        $(@).width('')
