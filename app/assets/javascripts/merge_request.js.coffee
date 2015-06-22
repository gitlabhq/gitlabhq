#= require jquery.waitforimages
#= require task_list

#= require merge_request_tabs

class @MergeRequest
  # Initialize MergeRequest behavior
  #
  # Options:
  #   action - String, current controller action
  #
  constructor: (@opts) ->
    @initContextWidget()
    this.$el = $('.merge-request')

    this.$('.show-all-commits').on 'click', =>
      this.showAllCommits()

    # `MergeRequests#new` has no tab-persisting or lazy-loading behavior
    unless @opts.action == 'new'
      new MergeRequestTabs(@opts)

    # Prevent duplicate event bindings
    @disableTaskList()

    if $("a.btn-close").length
      @initTaskList()

    $('.merge-request-details').waitForImages ->
      $('.issuable-affix').affix offset:
        top: ->
          @top = ($('.issuable-affix').offset().top - 70)
        bottom: ->
          @bottom = $('.footer').outerHeight(true)
      $('.issuable-affix').on 'affix.bs.affix', ->
        $(@).width($(@).outerWidth())
      .on 'affixed-top.bs.affix affixed-bottom.bs.affix', ->
        $(@).width('')

  # Local jQuery finder
  $: (selector) ->
    this.$el.find(selector)

  initContextWidget: ->
    $('.edit-merge_request.inline-update input[type="submit"]').hide()
    $(".context .inline-update").on "change", "select", ->
      $(this).submit()
    $(".context .inline-update").on "change", "#merge_request_assignee_id", ->
      $(this).submit()

  showAllCommits: ->
    this.$('.first-commits').remove()
    this.$('.all-commits').removeClass 'hide'

  initTaskList: ->
    $('.merge-request-details .js-task-list-container').taskList('enable')
    $(document).on 'tasklist:changed', '.merge-request-details .js-task-list-container', @updateTaskList

  disableTaskList: ->
    $('.merge-request-details .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.merge-request-details .js-task-list-container'

  # TODO (rspeicher): Make the merge request description inline-editable like a
  # note so that we can re-use its form here
  updateTaskList: ->
    patchData = {}
    patchData['merge_request'] = {'description': $('.js-task-list-field', this).val()}

    $.ajax
      type: 'PATCH'
      url: $('form.js-merge-request-update').attr('action')
      data: patchData
