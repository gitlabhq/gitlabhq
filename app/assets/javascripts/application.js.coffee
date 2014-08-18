# This is a manifest file that'll be compiled into including all the files listed below.
# Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
# be included in the compiled file accessible from http://example.com/assets/application.js
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
#= require jquery
#= require jquery.ui.all
#= require jquery_ujs
#= require jquery.cookie
#= require jquery.endless-scroll
#= require jquery.highlight
#= require jquery.history
#= require jquery.waitforimages
#= require jquery.atwho
#= require jquery.scrollTo
#= require jquery.blockUI
#= require jquery.sticky
#= require turbolinks
#= require jquery.turbolinks
#= require bootstrap
#= require select2
#= require raphael
#= require g.raphael-min
#= require g.bar-min
#= require branch-graph
#= require highlight.pack
#= require ace/ace
#= require ace/ext-searchbox
#= require ace/ext-modelist
#= require ace/mode-abap
#= require ace/mode-actionscript
#= require ace/mode-ada
#= require ace/mode-asciidoc
#= require ace/mode-assembly_x86
#= require ace/mode-autohotkey
#= require ace/mode-batchfile
#= require ace/mode-c9search
#= require ace/mode-c_cpp
#= require ace/mode-clojure
#= require ace/mode-cobol
#= require ace/mode-coffee
#= require ace/mode-coldfusion
#= require ace/mode-csharp
#= require ace/mode-css
#= require ace/mode-curly
#= require ace/mode-d
#= require ace/mode-dart
#= require ace/mode-diff
#= require ace/mode-django
#= require ace/mode-dot
#= require ace/mode-ejs
#= require ace/mode-erlang
#= require ace/mode-forth
#= require ace/mode-ftl
#= require ace/mode-glsl
#= require ace/mode-golang
#= require ace/mode-groovy
#= require ace/mode-haml
#= require ace/mode-handlebars
#= require ace/mode-haskell
#= require ace/mode-haxe
#= require ace/mode-html
#= require ace/mode-html_completions
#= require ace/mode-html_ruby
#= require ace/mode-ini
#= require ace/mode-jack
#= require ace/mode-jade
#= require ace/mode-java
#= require ace/mode-javascript
#= require ace/mode-json
#= require ace/mode-jsp
#= require ace/mode-jsx
#= require ace/mode-julia
#= require ace/mode-latex
#= require ace/mode-less
#= require ace/mode-liquid
#= require ace/mode-lisp
#= require ace/mode-livescript
#= require ace/mode-logiql
#= require ace/mode-lsl
#= require ace/mode-lua
#= require ace/mode-luahtml
#= require ace/mode-luapage
#= require ace/mode-lucene
#= require ace/mode-makefile
#= require ace/mode-markdown
#= require ace/mode-matlab
#= require ace/mode-mushcode
#= require ace/mode-mushcode_high_rules
#= require ace/mode-mysql
#= require ace/mode-nix
#= require ace/mode-objectivec
#= require ace/mode-ocaml
#= require ace/mode-pascal
#= require ace/mode-perl
#= require ace/mode-pgsql
#= require ace/mode-plain_text
#= require ace/mode-powershell
#= require ace/mode-prolog
#= require ace/mode-properties
#= require ace/mode-protobuf
#= require ace/mode-python
#= require ace/mode-r
#= require ace/mode-rdoc
#= require ace/mode-rhtml
#= require ace/mode-ruby
#= require ace/mode-rust
#= require ace/mode-sass
#= require ace/mode-scad
#= require ace/mode-scala
#= require ace/mode-scheme
#= require ace/mode-scss
#= require ace/mode-sh
#= require ace/mode-sjs
#= require ace/mode-snippets
#= require ace/mode-soy_template
#= require ace/mode-space
#= require ace/mode-sql
#= require ace/mode-stylus
#= require ace/mode-svg
#= require ace/mode-tcl
#= require ace/mode-tex
#= require ace/mode-text
#= require ace/mode-textile
#= require ace/mode-tmsnippet
#= require ace/mode-toml
#= require ace/mode-twig
#= require ace/mode-typescript
#= require ace/mode-vbscript
#= require ace/mode-velocity
#= require ace/mode-verilog
#= require ace/mode-vhdl
#= require ace/mode-xml
#= require ace/mode-yaml
#= require d3
#= require underscore
#= require nprogress
#= require nprogress-turbolinks
#= require dropzone
#= require semantic-ui/sidebar
#= require mousetrap
#= require shortcuts
#= require shortcuts_navigation
#= require shortcuts_dashboard_navigation
#= require shortcuts_issueable
#= require shortcuts_network
#= require_tree .

# Updates syntax highlighting of editor on current page depending on filename
# Filename is given with selector
window.updateAceModeOnFilenameChange = (selector) ->
  window.updateAceMode = (val) =>
    modelist = ace.require('ace/ext/modelist')
    ace_mode = modelist.getModeForPath(val).mode
    editor.session.setMode(ace_mode)

  updateAceMode($.trim($(selector).val()))

  $(selector).on 'input', ->
    val = $.trim($(@).val())
    if $(@).data('lastval') != val
      $(@).data('lastval', val)
      updateAceMode(val)

window.slugify = (text) ->
  text.replace(/[^-a-zA-Z0-9]+/g, '_').toLowerCase()

window.ajaxGet = (url) ->
  $.ajax({type: "GET", url: url, dataType: "script"})

window.showAndHide = (selector) ->

window.errorMessage = (message) ->
  ehtml = $("<p>")
  ehtml.addClass("error_message")
  ehtml.html(message)
  ehtml

window.split = (val) ->
  return val.split( /,\s*/ )

window.extractLast = (term) ->
  return split( term ).pop()

window.rstrip = (val) ->
  return val.replace(/\s+$/, '')

# Disable button if text field is empty
window.disableButtonIfEmptyField = (field_selector, button_selector) ->
  field = $(field_selector)
  closest_submit = field.closest('form').find(button_selector)

  closest_submit.disable() if rstrip(field.val()) is ""

  field.on 'input', ->
    if rstrip($(@).val()) is ""
      closest_submit.disable()
    else
      closest_submit.enable()

# Disable button if any input field with given selector is empty
window.disableButtonIfAnyEmptyField = (form, form_selector, button_selector) ->
  closest_submit = form.find(button_selector)
  empty = false
  form.find('input').filter(form_selector).each ->
    empty = true if rstrip($(this).val()) is ""

  if empty
    closest_submit.disable()
  else
    closest_submit.enable()

  form.keyup ->
    empty = false
    form.find('input').filter(form_selector).each ->
      empty = true if rstrip($(this).val()) is ""

    if empty
      closest_submit.disable()
    else
      closest_submit.enable()

window.sanitize = (str) ->
  return str.replace(/<(?:.|\n)*?>/gm, '')

window.linkify = (str) ->
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
  return str.replace(exp,"<a href='$1'>$1</a>")

window.simpleFormat = (str) ->
  linkify(sanitize(str).replace(/\n/g, '<br />'))

window.unbindEvents = ->
  $(document).unbind('scroll')
  $(document).off('scroll')

document.addEventListener("page:fetch", unbindEvents)

$ ->
  # Click a .one_click_select field, select the contents
  $(".one_click_select").on 'click', -> $(@).select()

  $('.remove-row').bind 'ajax:success', ->
    $(this).closest('li').fadeOut()

  # Initialize select2 selects
  $('select.select2').select2(width: 'resolve', dropdownAutoWidth: true)

  # Close select2 on escape
  $('.js-select2').bind 'select2-close', ->
    setTimeout ( ->
      $('.select2-container-active').removeClass('select2-container-active')
      $(':focus').blur()
    ), 1

  # Initialize tooltips
  $('.has_tooltip').tooltip()

  # Bottom tooltip
  $('.has_bottom_tooltip').tooltip(placement: 'bottom')

  # Form submitter
  $('.trigger-submit').on 'change', ->
    $(@).parents('form').submit()

  $("abbr.timeago").timeago()
  $('.js-timeago').timeago()

  # Flash
  if (flash = $(".flash-container")).length > 0
    flash.click -> $(@).fadeOut()
    flash.show()
    setTimeout (-> flash.fadeOut()), 5000

  # Disable form buttons while a form is submitting
  $('body').on 'ajax:complete, ajax:beforeSend, submit', 'form', (e) ->
    buttons = $('[type="submit"]', @)

    switch e.type
      when 'ajax:beforeSend', 'submit'
        buttons.disable()
      else
        buttons.enable()

  # Show/Hide the profile menu when hovering the account box
  $('.account-box').hover -> $(@).toggleClass('hover')

  # Commit show suppressed diff
  $(".diff-content").on "click", ".supp_diff_link", ->
    $(@).next('table').show()
    $(@).remove()

  # Show/hide comments on diff
  $("body").on "click", ".js-toggle-diff-comments", (e) ->
    $(@).find('i').
      toggleClass('icon-chevron-down').
      toggleClass('icon-chevron-up')
    $(@).closest(".diff-file").find(".notes_holder").toggle()
    e.preventDefault()

(($) ->
  # Disable an element and add the 'disabled' Bootstrap class
  $.fn.extend disable: ->
    $(@).attr('disabled', 'disabled').addClass('disabled')

  # Enable an element and remove the 'disabled' Bootstrap class
  $.fn.extend enable: ->
    $(@).removeAttr('disabled').removeClass('disabled')

)(jQuery)
