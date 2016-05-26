# Inspired by http://reed.github.io/turbolinks-compatibility/mathjax.html.

config =
  tex2jax:
    inlineMath: [['\\(', '\\)']]  # default for Asciidoctor
    displayMath: [['\\[', '\\]']]  # default for Asciidoctor
    ignoreClass: 'page-with-sidebar|navbar|nostem|nolatexmath'
    processClass: 'wiki'
  asciimath2jax:
    delimiters: [['\\$', '\\$']]  # default for Asciidoctor
    ignoreClass: 'page-with-sidebar|navbar|nostem|nolatexmath'
    processClass: 'wiki'
  TeX:
    equationNumbers:
      autoNumber: 'none'

isEnabled = ->
  $('.content').data('mathjax') == 'enabled'

load = ->
  $.ajax(
    dataType: 'script'
    cache: true
    url: "https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=#{gon.mathjax_config}"
  ).done =>
    window.MathJax.Hub.Config(config)

typeset = ->
  window.MathJax?.Hub.Queue(['Typeset', window.MathJax.Hub])

onPageLoad = ->
  return unless isEnabled()
  if window.MathJax
    typeset()
  else
    load()

$(document).ready onPageLoad
$(document).on 'page:load', onPageLoad
$(document).on 'mathjax:typeset', typeset
