# LineHighlighter
#
# Handles single- and multi-line selection and highlight for blob views.
#
#= require jquery.scrollTo
#
# ### Example Markup
#
#   <div id="blob-content-holder">
#     <div class="file-content">
#       <div class="line-numbers">
#         <a href="#L1" id="L1" data-line-number="1">1</a>
#         <a href="#L2" id="L2" data-line-number="2">2</a>
#         <a href="#L3" id="L3" data-line-number="3">3</a>
#         <a href="#L4" id="L4" data-line-number="4">4</a>
#         <a href="#L5" id="L5" data-line-number="5">5</a>
#       </div>
#       <pre class="code highlight">
#         <code>
#           <span id="LC1" class="line">...</span>
#           <span id="LC2" class="line">...</span>
#           <span id="LC3" class="line">...</span>
#           <span id="LC4" class="line">...</span>
#           <span id="LC5" class="line">...</span>
#         </code>
#       </pre>
#     </div>
#   </div>
#
class @LineHighlighter
  # CSS class applied to highlighted lines
  highlightClass: 'hll'

  # Internal copy of location.hash so we're not dependent on `location` in tests
  _hash: ''

  # Initialize a LineHighlighter object
  #
  # hash - String URL hash for dependency injection in tests
  constructor: (hash = location.hash) ->
    @_hash = hash

    @bindEvents()

    unless hash == ''
      range = @hashToRange(hash)

      if range[0]
        @highlightRange(range)

        # Scroll to the first highlighted line on initial load
        # Offset -50 for the sticky top bar, and another -100 for some context
        $.scrollTo("#L#{range[0]}", offset: -150)

  bindEvents: ->
    $('#blob-content-holder').on 'mousedown', 'a[data-line-number]', @clickHandler

    # While it may seem odd to bind to the mousedown event and then throw away
    # the click event, there is a method to our madness.
    #
    # If not done this way, the line number anchor will sometimes keep its
    # active state even when the event is cancelled, resulting in an ugly border
    # around the link and/or a persisted underline text decoration.

    $('#blob-content-holder').on 'click', 'a[data-line-number]', (event) ->
      event.preventDefault()

  clickHandler: (event) =>
    event.preventDefault()

    @clearHighlight()

    lineNumber = $(event.target).closest('a').data('line-number')
    current = @hashToRange(@_hash)

    unless current[0] && event.shiftKey
      # If there's no current selection, or there is but Shift wasn't held,
      # treat this like a single-line selection.
      @setHash(lineNumber)
      @highlightLine(lineNumber)
    else if event.shiftKey
      if lineNumber < current[0]
        range = [lineNumber, current[0]]
      else
        range = [current[0], lineNumber]

      @setHash(range[0], range[1])
      @highlightRange(range)

  # Unhighlight previously highlighted lines
  clearHighlight: ->
    $(".#{@highlightClass}").removeClass(@highlightClass)

  # Convert a URL hash String into line numbers
  #
  # hash - Hash String
  #
  # Examples:
  #
  #   hashToRange('#L5')    # => [5, null]
  #   hashToRange('#L5-15') # => [5, 15]
  #   hashToRange('#foo')   # => [null, null]
  #
  # Returns an Array
  hashToRange: (hash) ->
    matches = hash.match(/^#?L(\d+)(?:-(\d+))?$/)

    if matches && matches.length
      first = parseInt(matches[1])
      last  = if matches[2] then parseInt(matches[2]) else null

      [first, last]
    else
      [null, null]

  # Highlight a single line
  #
  # lineNumber - Line number to highlight
  highlightLine: (lineNumber) =>
    $("#LC#{lineNumber}").addClass(@highlightClass)

  # Highlight all lines within a range
  #
  # range - Array containing the starting and ending line numbers
  highlightRange: (range) ->
    if range[1]
      for lineNumber in [range[0]..range[1]]
        @highlightLine(lineNumber)
    else
      @highlightLine(range[0])

  # Set the URL hash string
  setHash: (firstLineNumber, lastLineNumber) =>
    if lastLineNumber
      hash = "#L#{firstLineNumber}-#{lastLineNumber}"
    else
      hash = "#L#{firstLineNumber}"

    @_hash = hash
    @__setLocationHash__(hash)

  # Make the actual hash change in the browser
  #
  # This method is stubbed in tests.
  __setLocationHash__: (value) ->
    # We're using pushState instead of assigning location.hash directly to
    # prevent the page from scrolling on the hashchange event
    history.pushState({turbolinks: false, url: value}, document.title, value)
