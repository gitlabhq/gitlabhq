((w) ->
  if not w.gl? then w.gl = {}
  if not gl.text? then gl.text = {}
  if not gl.mouse? then gl.mouse = {}

  gl.text.getSelectionText = ->
    text = ''
    if w.getSelection
      text = w.getSelection().toString()
    else if document.selection and document.selection.type is not "Control"
      text = document.selection.createRange().text
    text

  gl.mouse.isRightClick = (e) ->
    if not e? then e = window.event
    if e.which
      isItRightClick = (e.which is 3)
    else if e.button
      isItRightClick = (e.button is 2)
    isItRightClick


  $.fn.textPopup = (options) ->
    return this.each(->
      tooltipTemplate = _.template('
      <div class="text-selection-popup">
        <% _.each(buttons, function(button){ %>
          <a href="#" class="text-selection-icon" title="<%= button.title %>">
            <i class="<%= button.icon %>"></i>
          </a>
        <% }); %>
      </div>
      ')
      $(this).on('mousedown', (e) ->
        $('body').attr('mouse-top', e.clientY + window.pageYOffset)
        $('body').attr('mouse-left', e.clientX)

        if not gl.mouse.isRightClick(e) and gl.text.getSelectionText().length > 0
          $('.text-selection-popup').remove()
          document.getSelection().removeAllRanges()
      )

      $(this).on('mouseup', (e) ->
        $target = $(e.target)
        selectionText = gl.text.getSelectionText()
        if selectionText.length > 3 and not gl.mouse.isRightClick(e)
          mouseTopStart = $('body').attr('mouse-top')
          mouseTopEnd = e.clientY + w.pageYOffset
          if parseInt(mouseTopStart) < parseInt(mouseTopEnd)
            mouseTop = mouseTopStart
          else
            mouseTop = mouseTopEnd

          mouseLeftPosition = $('body').attr('mouse-left')
          mouseRightPosition = e.clientX
          mouseLeft = parseInt(mouseLeftPosition) + (parseInt(mouseRightPosition) - parseInt(mouseLeftPosition)) / 2
          $('body').append(tooltipTemplate(options))

          $('.text-selection-popup').css({
            position: 'absolute'
            top: parseInt(mouseTop) - 60
            left: parseInt(mouseLeft)
          })
      )
    )
) window