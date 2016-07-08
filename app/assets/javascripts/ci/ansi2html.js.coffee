class @Ansi2Html
  constructor: ->
    @_currentLine = 0
    @_ansiRegex = /\[[0-9]+;?[0-9]?m/g
    @_colorRegex = /\[[0-9]+;?[0-9]?m((.*))(\[0+;?m)?/g
    @_replaceLineRegex = /(\r|(\[([0-9]?)+k))/gi
    @_colors = ['black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white']
    @_html = []

  html: ->
    @_html

  convertTrace: (trace) ->
    if trace?
      @trace = trace.split('\n')

      for line, i in @trace
        @_currentLine = @_currentLine + 1
        @convertLine(line)

    return @

  convertLine: (line) ->
    prepend = true
    lineText = if line is '' then ' ' else line
    clearLineIndex = lineText.search(@_replaceLineRegex)

    lineEl = @createLine(lineText)

    if (clearLineIndex >= 0 and clearLineIndex is not lineText.length - 1) and lineText.indexOf('$') < 0
      prepend = false
      lastEl = @_html[@_html.length - 1]

      if lastEl.find('span').text().indexOf('$') is 1
        prepend = true
      else
        lineText = @removeAnsiCodes(lineText)
        lineText = @replaceLine(lineText)

        lastEl
          .find('span')
          .text(lineText)

    if prepend
      lineEl.prepend @lineLink()
      @_html.push(lineEl)

  createLine: (line) ->
    line = @replaceLine(line)
    line = @getInnerTextWithColors(line)

    $('<p />',
      id: "line-#{@_currentLine}"
      class: 'build-trace-line'
    ).append $('<span />').append line

  lineLink: ->
    $('<a />',
      class: 'build-trace-line-number'
      href: "#line-#{@_currentLine}"
      text: @_currentLine
    )

  getInnerTextWithColors: (line) ->
    matches = line.match(@_colorRegex)

    if matches?
      for match in matches
        color = match.match(@_ansiRegex)
        if color.length > 1
          color = color.slice(0, -1)

        color = color[color.length - 1]
        modifierSplit = color.split(/;|m/)
        color = modifierSplit[0].substring(1)
        colorInt = parseInt(color)
        colorText = @_colors[color[1]]
        modifier = modifierSplit[1][0]

        # Create inner span
        $span = $('<span />',
          text: @removeAnsiCodes(match)
          class: @getColorClass(colorText, @getLineType(color), modifier is "1")
        )
        line = line.replace(match, $span.get(0).outerHTML)
    else
      line = @removeAnsiCodes(line)
    line

  getLineType: (code) ->
    if code >= 40 and code < 90 or code >= 100
      'bg'
    else
      'fg'

  removeAnsiCodes: (line) ->
    line.replace(@_ansiRegex, '')

  replaceLine: (line) ->
    return line if line.indexOf('$') >= 0
    lineSplit = line.split(@_replaceLineRegex).filter (text) ->
      text = '' if not text?
      text.trim().length > 0

    if lineSplit.length > 0
      lineSplit[lineSplit.length - 1]
    else
      line

  getColorClass: (color, type, bold) ->
    bold = if bold then 'l-' else ''

    "term-#{type}-#{bold}#{color}"

  getModifierClass: (modifier) ->
    unless modifier is "1"
      if modifier is "3"
        "term-italic"
      else if modifier is "4"
        "term-underline"
      else if modifier is "8"
        "term-conceal"
      else if modifier is "9"
        "term-cross"
