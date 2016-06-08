((w) ->

  jQuery.timefor = (time, suffix, expiredLabel) ->

    return '' unless time

    suffix       or= 'remaining'
    expiredLabel or= 'Past due'

    jQuery.timeago.settings.allowFuture = yes

    { suffixFromNow } = jQuery.timeago.settings.strings
    jQuery.timeago.settings.strings.suffixFromNow = suffix

    timefor = $.timeago time

    if timefor.indexOf('ago') > -1
      timefor = expiredLabel

    jQuery.timeago.settings.strings.suffixFromNow = suffixFromNow

    return timefor

) window
