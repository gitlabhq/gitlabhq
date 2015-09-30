# Syntax Highlighter
#
# Applies a syntax highlighting color scheme CSS class to any element with the
# `js-syntax-highlight` class
#
# ### Example Markup
#
#   <div class="js-syntax-highlight"></div>
#
$.fn.syntaxHighlight = ->
  if $(this).hasClass('js-syntax-highlight')
    # Given the element itself, apply highlighting
    $(this).addClass(gon.user_color_scheme)
  else
    # Given a parent element, recurse to any of its applicable children
    $children = $(this).find('.js-syntax-highlight')
    $children.syntaxHighlight() if $children.length

$(document).on 'ready page:load', ->
  $('.js-syntax-highlight').syntaxHighlight()
