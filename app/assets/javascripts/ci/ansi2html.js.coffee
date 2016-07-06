class @Ansi2Html
  constructor: ->
    @_currentLine = 0
    @_colorRegex = /\[[0-9]+;[0-9]?m/g
    @_replaceLineRegex = /(\r|(\[[0-9]+k))/g
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
    codes = @getAnsiCodes(line)

    lineEl = @createLine(lineText)

    if lineText.indexOf(@_replaceLineRegex) >= 0 and lineText.indexOf('$') < 0
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

      if codes?
        lineEl
          .find('span')
          .addClass @getColorClass(codes.color, codes.type, codes.bold)
          .addClass @getModifierClass(codes.modifier)

      @_html.push(lineEl)

  createLine: (line) ->
    line = @removeAnsiCodes(line)
    line = @replaceLine(line)

    $('<p />',
      id: "line-#{@_currentLine}"
      class: 'build-trace-line'
    ).append $('<span />',
      text: @removeAnsiCodes(line)
    )

  lineLink: ->
    $('<a />',
      class: 'build-trace-line-number'
      href: "#line-#{@_currentLine}"
      text: @_currentLine
    )

  getAnsiCodes: (line) ->
    matches = line.match(@_colorRegex)

    if matches?
      match = matches[0]
      modifierSplit = match.split(';')
      color = modifierSplit[0].substring(1)
      colorInt = parseInt(color)
      colorText = @_colors[color[1]]
      modifier = modifierSplit[1][0]

      if colorText?
        return {
          color: colorText
          modifier: modifier
          bold: modifier is "1"
          type: @getLineType(color)
        }

  getLineType: (code) ->
    if code >= 40 and code < 90 or code >= 100
      'bg'
    else
      'fg'

  removeAnsiCodes: (line) ->
    line.replace(@_colorRegex, '')

  replaceLine: (line) ->
    lineSplit = line.split(@_replaceLineRegex)
    lineSplit[lineSplit.length - 1]

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
