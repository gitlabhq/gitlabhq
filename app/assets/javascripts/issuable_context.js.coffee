#= require jquery.waitforimages

class @IssuableContext
  constructor: ->
    new UsersSelect()
    $('select.select2').select2({width: 'resolve', dropdownAutoWidth: true})

    $(".issuable-sidebar .inline-update").on "change", "select", ->
      $(this).submit()
    $(".issuable-sidebar .inline-update").on "change", ".js-assignee", ->
      $(this).submit()

    $('.issuable-details').waitForImages ->
      $('.issuable-affix').on 'affix.bs.affix', ->
        $(@).width($(@).outerWidth())
      .on 'affixed-top.bs.affix affixed-bottom.bs.affix', ->
        $(@).width('')
      $discussion = $('.issuable-discussion')
      $sidebar = $('.issuable-sidebar')
      discussionHeight = $discussion.height()
      sidebarHeight = $sidebar.height()
      console.log(sidebarHeight,discussionHeight)
      if sidebarHeight > discussionHeight
        $discussion.height(sidebarHeight + 50)
        console.log('fixing issues')
        return
      # No affix if discussion is smaller than sidebar
      $('.issuable-affix').affix offset:
        top: ->
          @top = ($('.issuable-affix').offset().top - 70)
        bottom: ->
          @bottom = $('.footer').outerHeight(true)

    $(".edit-link").click (e) ->
      block = $(@).parents('.block')
      block.find('.selectbox').show()
      block.find('.value').hide()
      block.find('.js-select2').select2("open")
