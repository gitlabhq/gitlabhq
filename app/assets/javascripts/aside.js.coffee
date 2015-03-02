class @Aside
  constructor: ->
    $(document).off "click", "a.show-aside"
    $(document).on "click", 'a.show-aside', (e) ->
      e.preventDefault()
      btn = $(e.currentTarget)
      icon = btn.find('i')
      console.log('1')

      if icon.hasClass('fa-angle-left')
        btn.parent().find('section').hide()
        btn.parent().find('aside').fadeIn()
        icon.removeClass('fa-angle-left').addClass('fa-angle-right')
      else
        btn.parent().find('aside').hide()
        btn.parent().find('section').fadeIn()
        icon.removeClass('fa-angle-right').addClass('fa-angle-left')
