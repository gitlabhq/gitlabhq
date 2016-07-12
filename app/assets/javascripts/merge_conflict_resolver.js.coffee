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

    headHeaderText   = 'HEAD//our changes'
    originHeaderText = 'origin//their changes'

    for file in data.files
      file.parallelLines  = { left: [], right: [] }
      file.inlineLines    = []
      file.shortCommitSha = file.commit_sha.slice 0, 7
      currentLineType     = 'old'

      for section in file.sections
        { conflict, lines, id } = section

        if conflict
          file.parallelLines.left.push  { isHeader: yes, id, text: headHeaderText, cssClass: 'head' }
          file.parallelLines.right.push { isHeader: yes, id, text: originHeaderText, cssClass: 'origin' }

          file.inlineLines.push { isHeader: yes, id, text: headHeaderText, type: 'old', cssClass: 'head' }

        for line in lines
          if line.type in ['new', 'old'] and currentLineType isnt line.type
            currentLineType = line.type
            # FIXME: Find a better way to add a new line
            file.inlineLines.push { lineType: 'emptyLine', text: '<span> </span>' }

          line.conflict = conflict
          line.cssClass = if line.type is 'old' then 'head' else if line.type is 'new' then 'origin' else ''
          file.inlineLines.push line

          if conflict
            if line.type is 'old'
              line = { lineType: 'conflict', lineNumber: line.old_line, text: line.text, cssClass: 'head' }
              file.parallelLines.left.push  line
            else if line.type is 'new'
              line = { lineType: 'conflict', lineNumber: line.new_line, text: line.text, cssClass: 'origin' }
              file.parallelLines.right.push line
            else
              console.log 'unhandled line type...', line
          else
            file.parallelLines.left.push  { lineType: 'context', lineNumber: line.old_line, text: line.text }
            file.parallelLines.right.push { lineType: 'context', lineNumber: line.new_line, text: line.text }

        if conflict
          file.inlineLines.push { isHeader: yes, id, type: 'new', text: originHeaderText, cssClass: 'origin' }

    return data


  getInitialData: ->

    diffViewType = $.cookie 'diff_view'

    return {
      isLoading     : yes
      diffView      : diffViewType
      conflictsData : {}
      isParallel    : diffViewType is 'parallel'
    }
