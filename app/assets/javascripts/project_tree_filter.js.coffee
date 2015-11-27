class @ProjectTreeFilter
  constructor: ->

    # focus text input box
    $(".tree-filter-input").focus()

    # bind keyup event at text input box
    $(document).off "keyup", ".tree-filter-input"
    $(document).on "keyup", ".tree-filter-input", @treeFilter

    $(".tree-filter-input").trigger( "keyup" ) if $(".tree-filter-input").val()

  # filter tree
  treeFilter: (e) ->
    searchCharArr = $(this).val().split("")
    regEx = makeRegEx searchCharArr

    # file list count
    showCnt = 20;

    $(this).closest('.tree-holder').find('#files-slider .tree-item').each (index, element) ->
      if showCnt > 0
        text = $(element).find("a").text()
        result = regEx.exec text

        if result
          markTxt = highlightText result, searchCharArr
          $(element).find("a").html(text.replace(result, markTxt))
          $(this).show()
          showCnt--;
        else
          $(this).hide()
      else
        $(this).hide()

  # highlight text(awefwbwgtc -> <b>a</b>wefw<b>b</b>wgt<b>c</b> )
  highlightText = (txt, charArr) ->
    result = ""
    target = txt.toString()
    for char in charArr
      charIdx = target.toLowerCase().indexOf char.toLowerCase()
      result += "#{target.substring 0, charIdx}#{(target.charAt charIdx).bold()}"
      target = target.substring charIdx + 1
    return result

  # generate regular expression(abc -> a[^b]*b[^c]*c)
  makeRegEx = (searchCharArr) ->
    regExStr = ""
    for char in searchCharArr
      if regExStr.length > 0
        regExStr += "[^#{char}]*#{char}"
      else
        regExStr += char
    return new RegExp regExStr, "i"
