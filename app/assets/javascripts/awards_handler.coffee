class @AwardsHandler
  constructor: (@getEmojisUrl, @postEmojiUrl, @noteableType, @noteableId, @unicodes) ->
    $('.js-add-award').on 'click', (event) =>
      event.stopPropagation()
      event.preventDefault()

      @showEmojiMenu()

    $('html').on 'click', (event) ->
      if !$(event.target).closest('.emoji-menu').length
        if $('.emoji-menu').is(':visible')
          $('.emoji-menu').removeClass 'is-visible'

    $('.awards')
      .off 'click'
      .on 'click', '.js-emoji-btn', @handleClick

    @renderFrequentlyUsedBlock()

  handleClick: (e) ->
    e.preventDefault()
    emoji = $(this)
      .find('.icon')
      .data 'emoji'

    if emoji is 'thumbsup' and awardsHandler.didUserClickEmoji $(this), 'thumbsdown'
      awardsHandler.addAward 'thumbsdown'

    else if emoji is 'thumbsdown' and awardsHandler.didUserClickEmoji $(this), 'thumbsup'
      awardsHandler.addAward 'thumbsup'

    awardsHandler.addAward emoji

    $(this).trigger 'blur'

  didUserClickEmoji: (that, emoji) ->
    if $(that).siblings("button:has([data-emoji=#{emoji}])").attr('data-original-title')
      $(that).siblings("button:has([data-emoji=#{emoji}])").attr('data-original-title').indexOf('me') > -1

  showEmojiMenu: ->
    if $('.emoji-menu').length
      if $('.emoji-menu').is '.is-visible'
        $('.emoji-menu').removeClass 'is-visible'
        $('#emoji_search').blur()
      else
        $('.emoji-menu').addClass 'is-visible'
        $('#emoji_search').focus()
    else
      $('.js-add-award').addClass 'is-loading'
      $.get @getEmojisUrl, (response) =>
        $('.js-add-award').removeClass 'is-loading'
        $('.js-award-holder').append response
        setTimeout =>
          $('.emoji-menu').addClass 'is-visible'
          $('#emoji_search').focus()
          @setupSearch()
        , 200

  addAward: (emoji) ->
    @postEmoji emoji, =>
      @addAwardToEmojiBar(emoji)

    $('.emoji-menu').removeClass 'is-visible'

  addAwardToEmojiBar: (emoji) ->
    @addEmojiToFrequentlyUsedList(emoji)

    if @exist(emoji)
      if @isActive(emoji)
        @decrementCounter(emoji)
      else
        counter = @findEmojiIcon(emoji).siblings('.js-counter')
        counter.text(parseInt(counter.text()) + 1)
        counter.parent().addClass('active')
        @addMeToAuthorList(emoji)
    else
      @createEmoji(emoji)

  exist: (emoji) ->
    @findEmojiIcon(emoji).length > 0

  isActive: (emoji) ->
    @findEmojiIcon(emoji).parent().hasClass('active')

  decrementCounter: (emoji) ->
    counter = @findEmojiIcon(emoji).siblings('.js-counter')
    emojiIcon = counter.parent()
    if parseInt(counter.text()) > 1
      counter.text(parseInt(counter.text()) - 1)
      emojiIcon.removeClass('active')
      @removeMeFromAuthorList(emoji)
    else if emoji == 'thumbsup' || emoji == 'thumbsdown'
      emojiIcon.tooltip('destroy')
      counter.text(0)
      emojiIcon.removeClass('active')
      @removeMeFromAuthorList(emoji)
    else
      emojiIcon.tooltip('destroy')
      emojiIcon.remove()

  removeMeFromAuthorList: (emoji) ->
    awardBlock = @findEmojiIcon(emoji).parent()
    authors = awardBlock
      .attr('data-original-title')
      .split(', ')
    authors.splice(authors.indexOf('me'),1)
    awardBlock
      .closest('.js-emoji-btn')
      .attr('data-original-title', authors.join(', '))
    @resetTooltip(awardBlock)

  addMeToAuthorList: (emoji) ->
    awardBlock = @findEmojiIcon(emoji).parent()
    origTitle = awardBlock.attr('data-original-title').trim()
    authors = []
    if origTitle
      authors = origTitle.split(', ')
    authors.push('me')
    awardBlock.attr('data-original-title', authors.join(', '))
    @resetTooltip(awardBlock)

  resetTooltip: (award) ->
    award.tooltip('destroy')

    # "destroy" call is asynchronous and there is no appropriate callback on it, this is why we need to set timeout.
    setTimeout (->
      award.tooltip()
    ), 200


  createEmoji: (emoji) ->
    emojiCssClass = @resolveNameToCssClass(emoji)

    nodes = []
    nodes.push(
      "<button class='btn award-control js-emoji-btn has-tooltip active' data-original-title='me'>",
      "<div class='icon emoji-icon #{emojiCssClass}' data-emoji='#{emoji}'></div>",
      "<span class='award-control-text js-counter'>1</span>",
      "</button>"
    )

    $(nodes.join("\n"))
      .insertBefore('.js-award-holder')
      .find('.emoji-icon')
      .data('emoji', emoji)
    $('.award-control').tooltip()

  resolveNameToCssClass: (emoji) ->
    emojiIcon = $(".emoji-menu-content [data-emoji='#{emoji}']")

    if emojiIcon.length > 0
      unicodeName = emojiIcon.data('unicode-name')
    else
      # Find by alias
      unicodeName = $(".emoji-menu-content [data-aliases*=':#{emoji}:']").data('unicode-name')

    "emoji-#{unicodeName}"

  postEmoji: (emoji, callback) ->
    $.post @postEmojiUrl, { note: {
      note: ":#{emoji}:"
      noteable_type: @noteableType
      noteable_id: @noteableId
    }},(data) ->
      if data.ok
        callback.call()

  findEmojiIcon: (emoji) ->
    $(".awards > .js-emoji-btn [data-emoji='#{emoji}']")

  scrollToAwards: ->
    $('body, html').animate({
      scrollTop: $('.awards').offset().top - 80
    }, 200)

  addEmojiToFrequentlyUsedList: (emoji) ->
    frequentlyUsedEmojis = @getFrequentlyUsedEmojis()
    frequentlyUsedEmojis.push(emoji)
    $.cookie('frequently_used_emojis', frequentlyUsedEmojis.join(','), { expires: 365 })

  getFrequentlyUsedEmojis: ->
    frequentlyUsedEmojis = ($.cookie('frequently_used_emojis') || '').split(',')
    _.compact(_.uniq(frequentlyUsedEmojis))

  renderFrequentlyUsedBlock: ->
    if $.cookie('frequently_used_emojis')
      frequentlyUsedEmojis = @getFrequentlyUsedEmojis()

      ul = $('<ul>')

      for emoji in frequentlyUsedEmojis
        do (emoji) ->
          $(".emoji-menu-content [data-emoji='#{emoji}']").closest('li').clone().appendTo(ul)

      $('input.emoji-search').after(ul).after($('<h5>').text('Frequently used'))

  setupSearch: ->
    $('input.emoji-search').keyup (ev) =>
      term = $(ev.target).val()

      # Clean previous search results
      $('ul.emoji-menu-search, h5.emoji-search').remove()

      if term
        # Generate a search result block
        h5 = $('<h5>').text('Search results').addClass('emoji-search')
        foundEmojis = @searchEmojis(term).show()
        ul = $('<ul>').addClass('emoji-menu-list emoji-menu-search').append(foundEmojis)
        $('.emoji-menu-content ul, .emoji-menu-content h5').hide()
        $('.emoji-menu-content').append(h5).append(ul)
      else
        $('.emoji-menu-content').children().show()

  searchEmojis: (term)->
    $(".emoji-menu-content [data-emoji*='#{term}']").closest("li").clone()
