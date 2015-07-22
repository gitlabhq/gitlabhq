class @Diff
  UNFOLD_COUNT = 20
  constructor: ->
    $(document).off('click', '.js-unfold')
    $(document).on('click', '.js-unfold', (event) =>
      target = $(event.target)
      unfoldBottom = target.hasClass('js-unfold-bottom')
      unfold = true

      [old_line, line_number] = @lineNumbers(target.parent())
      offset = line_number - old_line

      if unfoldBottom
        line_number += 1
        since = line_number
        to = line_number + UNFOLD_COUNT
      else
        [prev_old_line, prev_new_line] = @lineNumbers(target.parent().prev())
        line_number -= 1
        to = line_number
        if line_number - UNFOLD_COUNT > prev_new_line + 1
          since = line_number - UNFOLD_COUNT
        else
          since = prev_new_line + 1
          unfold = false

      link = target.parents('.diff-file').attr('data-blob-diff-path')
      params =
        since: since
        to: to
        bottom: unfoldBottom
        offset: offset
        unfold: unfold
        # indent is used to compensate for single space indent to fit
        # '+' and '-' prepended to diff lines,
        # see https://gitlab.com/gitlab-org/gitlab-ce/issues/707
        indent: 1

      $.get(link, params, (response) =>
        target.parent().replaceWith(response)
      )
    )

  lineNumbers: (line) ->
    return ([0, 0]) unless line.children().length
    lines = line.children().slice(0, 2)
    line_numbers = ($(l).attr('data-linenumber') for l in lines)
    (parseInt(line_number) for line_number in line_numbers)
