$ ->
  # Toggle line wrapping in diff.
  #
  # %div.diff-file
  #   %input.js-toggle-diff-line-wrap
  #   %td.line_content
  #
  $("body").on "click", ".js-toggle-diff-line-wrap", (e) ->
    diffFile = $(@).closest(".diff-file")
    if $(@).is(":checked")
      diffFile.addClass("diff-wrap-lines")
    else
      diffFile.removeClass("diff-wrap-lines")

