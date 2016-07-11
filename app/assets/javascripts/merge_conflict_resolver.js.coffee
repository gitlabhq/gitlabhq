#= require lib/vue

class window.MergeConflictResolver extends Vue

  constructor: (options = {}) ->

    options.el      = '#conflicts'
    options.data    = @getInitialData()
    options.created = -> @fetchData()
    options.name    = 'MergeConflictResolver'

    super options

    window.v = this


  fetchData: ->

    $.ajax
      url    : '/emojis'
      success: (response) =>
        @handleResponse window.mergeConflictsData


  handleResponse: (data) ->

    @isLoading     = no
    @conflictsData = @decorateData data


  handleViewTypeChange: (newType) ->

    return if newType is @diffView
    return unless newType in [ 'parallel', 'inline' ]

    @diffView = newType
    $.cookie 'diff_view', newType
    @isParallel = @diffView is 'parallel'

    # FIXME: Maybe even better with vue.js
    $('.container-fluid').toggleClass 'container-limited'


  handleSelected: (sectionId, selection) ->

    console.log sectionId, selection


  decorateData: (data) ->

    for file in data.files
      file.parallelLines = { left: [], right: [] }
      file.inlineLines   = []
      currentLineType    = 'old'

      for section in file.sections
        { conflict, lines, id } = section

        if conflict
          header = { lineType: 'header', id }
          file.parallelLines.left.push  header
          file.parallelLines.right.push header

          header.type = 'old'
          file.inlineLines.push header

        for line in lines
          if line.type in ['new', 'old'] and currentLineType isnt line.type
            currentLineType = line.type
            # FIXME: Find a better way to add a new line
            file.inlineLines.push { lineType: 'emptyLine', text: '<span> </span>' }

          line.conflict = conflict
          file.inlineLines.push line

          if conflict
            if line.type is 'old'
              line = { lineType: 'conflict', lineNumber: line.old_line, text: line.text }
              file.parallelLines.left.push  line
            else if line.type is 'new'
              line = { lineType: 'conflict', lineNumber: line.new_line, text: line.text }
              file.parallelLines.right.push line
            else
              console.log 'unhandled line type...', line
          else
            file.parallelLines.left.push  { lineType: 'context', lineNumber: line.old_line, text: line.text }
            file.parallelLines.right.push { lineType: 'context', lineNumber: line.new_line, text: line.text }

        if conflict
          file.inlineLines.push { lineType: 'header', id, type: 'new' }

    console.log data
    return data


  getInitialData: ->

    diffViewType = $.cookie 'diff_view'

    return {
      isLoading     : yes
      diffView      : diffViewType
      conflictsData : {}
      isParallel    : diffViewType is 'parallel'
    }
