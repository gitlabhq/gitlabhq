BoardList = Vue.extend
  props:
    disabled: Boolean
    boardId: [Number, String]
    filters: Object
    issues: Array
    query: String
  data: ->
    scrollOffset: 20
    loadMore: false
  computed:
    newDone: -> BoardsStore.state.done
  methods:
    listHeight: -> this.$els.list.getBoundingClientRect().height
    scrollHeight: -> this.$els.list.scrollHeight
    scrollTop: -> this.$els.list.scrollTop + this.listHeight()
    loadFromLastId: ->
      this.loadMore = true
      setTimeout =>
        this.loadMore = false
      , 2000
    customFilter: (issue) ->
      returnIssue = issue
      if this.filters.author?.id
        if not issue.author? or issue.author?.id != this.filters.author.id
          returnIssue = null

      if this.filters.assignee?.id
        if not issue.assignee? or issue.assignee?.id != this.filters.assignee.id
          returnIssue = null

      if this.filters.milestone?.id
        if not issue.milestone? or issue.milestone?.id != this.filters.milestone.id
          returnIssue = null

      return returnIssue
  ready: ->
    Sortable.create this.$els.list,
      group: 'issues'
      disabled: this.disabled
      scrollSensitivity: 150
      scrollSpeed: 50
      forceFallback: true
      fallbackClass: 'is-dragging'
      ghostClass: 'is-ghost'
      onAdd: (e) ->
        fromBoardId = e.from.getAttribute('data-board')
        fromBoardId = parseInt(fromBoardId) || fromBoardId
        toBoardId = e.to.getAttribute('data-board')
        toBoardId = parseInt(toBoardId) || toBoardId
        issueId = parseInt(e.item.getAttribute('data-issue'))

        BoardsStore.moveCardToBoard(fromBoardId, toBoardId, issueId, e.newIndex)
      onUpdate: (e) ->
        console.log e.newIndex, e.oldIndex

    # Scroll event on list to load more
    this.$els.list.onscroll = =>
      if (this.scrollTop() > this.scrollHeight() - this.scrollOffset) and !this.loadMore
        this.loadFromLastId()

Vue.component('board-list', BoardList)
