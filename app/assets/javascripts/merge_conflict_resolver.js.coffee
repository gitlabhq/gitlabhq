#= require lib/vue

class window.MergeConflictResolver extends Vue

  constructor: (options = {}) ->

    options.el       = '#conflicts'
    options.data     = @getInitialData()
    options.name     = 'MergeConflictResolver'
    options.created  = -> @fetchData()
    options.computed =
      conflictsCount : -> @getConflictsCount()
      resolvedCount  : -> @getResolvedCount()
      allResolved    : -> @isAllResolved()

    super options

    window.v = this


  fetchData: ->

    $.ajax
      url    : './conflicts.json'
      success: (response) =>
        @handleResponse response


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

    @resolutionData[sectionId] = selection

    #FIXME: Dry!!
    for file in @conflictsData.files
      for line in file.inlineLines
        if line.id is sectionId and (line.conflict or line.isHeader)
          if selection is 'head' and line.isHead
            line.isSelected = yes
            line.isUnselected = no
          else if selection is 'origin' and line.isOrigin
            line.isSelected = yes
            line.isUnselected = no
          else
            line.isUnselected = yes
            line.isSelected = no

      for section, lines of file.parallelLines
        for line in lines
          if line.id is sectionId and (line.lineType is 'conflict' or line.isHeader)
            if selection is 'head' and line.isHead
              line.isSelected = yes
              line.isUnselected = no
            else if selection is 'origin' and line.isOrigin
              line.isSelected = yes
              line.isUnselected = no
            else
              line.isUnselected = yes
              line.isSelected = no


  decorateData: (data) ->

    headHeaderText   = 'HEAD//our changes'
    originHeaderText = 'origin//their changes'
    data.shortCommitSha = data.commit_sha.slice 0, 7
    data.commitMessage = data.commit_message

    @updateResolutionsData data

    # FIXME: Add comments and separate parallel and inline data decoration
    for file in data.files
      file.parallelLines  = { left: [], right: [] }
      file.inlineLines    = []
      currentLineType     = 'old'

      for section in file.sections
        { conflict, lines, id } = section

        if conflict
          # FIXME: Make these lines better
          file.parallelLines.left.push  { isHeader: yes, id, richText: headHeaderText, section: 'head', isHead: yes, isSelected: no, isUnselected: no }
          file.parallelLines.right.push { isHeader: yes, id, richText: originHeaderText, section: 'origin', isOrigin: yes, isSelected: no, isUnselected: no }

          file.inlineLines.push { isHeader: yes, id, richText: headHeaderText, type: 'old', section: 'head', isHead: yes, isSelected: no, isUnselected: no }

        for line in lines
          if line.type in ['new', 'old'] and currentLineType isnt line.type
            currentLineType = line.type
            # FIXME: Find a better way to add a new line
            file.inlineLines.push { lineType: 'emptyLine', richText: '<span> </span>' }

          # FIXME: Make these lines better
          line.conflict = conflict
          line.id = id
          line.isHead = line.type is 'new'
          line.isOrigin = line.type is 'old'
          line.isSelected = no
          line.isUnselected = no
          line.richText = line.rich_text
          file.inlineLines.push line

          if conflict
            if line.type is 'old'
              line = { lineType: 'conflict', lineNumber: line.old_line, richText: line.rich_text, section: 'origin', id, isSelected: no, isUnselected: no, isOrigin: yes }
              file.parallelLines.left.push  line
            else if line.type is 'new'
              line = { lineType: 'conflict', lineNumber: line.new_line, richText: line.rich_text, section: 'head', id, isSelected: no, isUnselected: no, isHead: yes }
              file.parallelLines.right.push line
            else
              console.log 'unhandled line type...', line
          else
            file.parallelLines.left.push  { lineType: 'context', lineNumber: line.old_line, richText: line.rich_text }
            file.parallelLines.right.push { lineType: 'context', lineNumber: line.new_line, richText: line.rich_text }

        if conflict
          file.inlineLines.push { isHeader: yes, id, type: 'new', richText: originHeaderText, section: 'origin', isOrigin: yes, isSelected: no, isUnselected: no }

    return data


  getConflictsCount: -> return Object.keys(@resolutionData).length


  getResolvedCount: ->

    count = 0
    count++ for id, resolution of @resolutionData when resolution

    return count


  isAllResolved: -> return @resolvedCount is @conflictsCount


  updateResolutionsData: (data) ->

    for file in data.files
      for section in file.sections when section.conflict
        @$set "resolutionData.#{section.id}", no


  getInitialData: ->

    diffViewType = $.cookie 'diff_view'

    return {
      isLoading      : yes
      isParallel     : diffViewType is 'parallel'
      diffView       : diffViewType
      conflictsData  : {}
      resolutionData : {}
    }
