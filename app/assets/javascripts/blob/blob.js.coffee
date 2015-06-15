# BlobView
#
# Handles single- and multi-line selection and highlight for blob views.
#
#= require jquery.scrollTo
#
# ### Example Markup
#
#   <div id="tree-content-holder">
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
class @BlobView
  # Internal copy of location.hash so we're not dependent on `location` in tests
  @_hash = ''

  # Initialize a BlobView object
  #
  # hash - String URL hash for dependency injection in tests
  constructor: (hash = location.hash) ->
    @_hash = hash

    @bindEvents()

    unless hash == ''
      range = @hashToRange(hash)

      unless isNaN(range[0])
        @highlightRange(range)

        # Scroll to the first highlighted line on initial load
        # Offset -50 for the sticky top bar, and another -100 for some context
        $.scrollTo("#L#{range[0]}", offset: -150)

  bindEvents: ->
    $('#tree-content-holder').on 'mousedown', 'a[data-line-number]', @clickHandler

    # While it may seem odd to bind to the mousedown event and then throw away
    # the click event, there is a method to our madness.
    #
    # If not done this way, the line number anchor will sometimes keep its
    # active state even when the event is cancelled, resulting in an ugly border
    # around the link and/or a persisted underline text decoration.

    $('#tree-content-holder').on 'click', 'a[data-line-number]', (event) ->
      event.preventDefault()

  clickHandler: (event) =>
    event.preventDefault()

    @clearHighlight()

    lineNumber = $(event.target).data('line-number')
    current = @hashToRange(@_hash)

    if isNaN(current[0]) or !event.shiftKey
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
    $('.hll').removeClass('hll')

  # Convert a URL hash String into line numbers
  #
  # hash - Hash String
  #
  # Examples:
  #
  #   hashToRange('#L5')    # => [5, NaN]
  #   hashToRange('#L5-15') # => [5, 15]
  #   hashToRange('#foo')   # => [NaN, NaN]
  #
  # Returns an Array
  hashToRange: (hash) ->
    first = parseInt(hash.replace(/^#L(\d+)/, '$1'))
    last  = parseInt(hash.replace(/^#L\d+-(\d+)/, '$1'))

    [first, last]

  # Highlight a single line
  #
  # lineNumber - Number to highlight. Must be parsable as an Integer.
  #
  # Returns undefined if lineNumber is not parsable as an Integer.
  highlightLine: (lineNumber) ->
    return if isNaN(parseInt(lineNumber))

    $("#LC#{lineNumber}").addClass('hll')

  # Highlight all lines within a range
  #
  # range - An Array of starting and ending line numbers.
  #
  # Examples:
  #
  #   # Highlight lines 5 through 15
  #   highlightRange([5, 15])
  #
  #   # The first value is required, and must be a number
  #   highlightRange(['foo', 15]) # Invalid, returns undefined
  #   highlightRange([NaN, NaN])  # Invalid, returns undefined
  #
  #   # The second value is optional; if omitted, only highlights the first line
  #   highlightRange([5, NaN]) # Valid
  #
  # Returns undefined if the first line is NaN.
  highlightRange: (range) ->
    return if isNaN(range[0])

    if isNaN(range[1])
      @highlightLine(range[0])
    else
      for lineNumber in [range[0]..range[1]]
        @highlightLine(lineNumber)

  setHash: (firstLineNumber, lastLineNumber) =>
    return if isNaN(parseInt(firstLineNumber))

    if isNaN(parseInt(lastLineNumber))
      hash = "#L#{firstLineNumber}"
    else
      hash = "#L#{firstLineNumber}-#{lastLineNumber}"

    @_hash = hash
    @__setLocationHash__(hash)

  # Make the actual hash change in the browser
  #
  # This method is stubbed in tests.
  __setLocationHash__: (value) ->
    # We're using pushState instead of assigning location.hash directly to
    # prevent the page from scrolling on the hashchange event
    history.pushState({turbolinks: false, url: value}, document.title, value)
