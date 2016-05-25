class @AwardsHandler

  constructor: ->

    @aliases = emojiAliases()

    $(document)
      .off 'click', '.js-add-award'
      .on  'click', '.js-add-award', (event) =>
        event.stopPropagation()
        event.preventDefault()

        @showEmojiMenu $(event.currentTarget)

    $('html').on 'click', (event) ->
      unless $(event.target).closest('.emoji-menu').length
        if $('.emoji-menu').is(':visible')
          $('.js-add-award.is-active').removeClass 'is-active'
          $('.emoji-menu').removeClass 'is-visible'

    $(document)
      .off 'click', '.js-emoji-btn'
      .on  'click', '.js-emoji-btn', @handleClick


  handleClick: (e) =>

    e.preventDefault()

    emoji = $(e.currentTarget).find('.icon').data 'emoji'
    @getVotesBlock().addClass 'js-awards-block'
    @addAward @getAwardUrl(), emoji


  showEmojiMenu: ($addBtn) ->

    $menu = $('.emoji-menu')

    if $menu.length
      $holder = $addBtn.closest('.js-award-holder')

      if $menu.is '.is-visible'
        $addBtn.removeClass 'is-active'
        $menu.removeClass 'is-visible'
        $('#emoji_search').blur()
      else
        $addBtn.addClass 'is-active'
        @positionMenu($menu, $addBtn)

        $menu.addClass 'is-visible'
        $('#emoji_search').focus()
    else
      $addBtn.addClass 'is-loading is-active'
      url = $addBtn.data 'award-menu-url'

      @createEmojiMenu url, =>
        $addBtn.removeClass 'is-loading'
        $menu = $('.emoji-menu')
        @positionMenu($menu, $addBtn)
        @renderFrequentlyUsedBlock()

        setTimeout =>
          $menu.addClass 'is-visible'
          $('#emoji_search').focus()
          @setupSearch()
        , 200


  createEmojiMenu: (awardMenuUrl, callback) ->

    $.get awardMenuUrl, (response) =>
      $('body').append response
      callback()


  positionMenu: ($menu, $addBtn) ->
    position = $addBtn.data('position')

    # The menu could potentially be off-screen or in a hidden overflow element
    # So we position the element absolute in the body
    css =
      top: "#{$addBtn.offset().top + $addBtn.outerHeight()}px"

    if position? and position is 'right'
      css.left = "#{($addBtn.offset().left - $menu.outerWidth()) + 20}px"
      $menu.addClass 'is-aligned-right'
    else
      css.left = "#{$addBtn.offset().left}px"
      $menu.removeClass 'is-aligned-right'

    $menu.css(css)


  addAward: (awardUrl, emoji, checkMutuality = yes) ->

    emoji = @normilizeEmojiName(emoji)
    @postEmoji awardUrl, emoji, =>
      @addAwardToEmojiBar(emoji, checkMutuality)

      $('.js-awards-block-current').removeClass 'js-awards-block-current'

    $('.emoji-menu').removeClass 'is-visible'


  addAwardToEmojiBar: (emoji, checkForMutuality = yes) ->

    @checkMutuality emoji  if checkForMutuality
    @addEmojiToFrequentlyUsedList(emoji)

    emoji = @normilizeEmojiName(emoji)
    $emojiBtn = @findEmojiIcon(emoji).parent()

    if $emojiBtn.length > 0
      if @isActive($emojiBtn)
        @decrementCounter($emojiBtn, emoji)
      else
        counter = $emojiBtn.find('.js-counter')
        counter.text(parseInt(counter.text()) + 1)
        $emojiBtn.addClass('active')
        @addMeToUserList(emoji)
    else
      @createEmoji(emoji)


  getVotesBlock: -> return $ '.awards.js-awards-block'


  getAwardUrl: -> @getVotesBlock().data 'award-url'


  checkMutuality: (emoji) ->

    awardUrl = @getAwardUrl()

    if emoji in [ 'thumbsup', 'thumbsdown' ]
      mutualVote = if emoji is 'thumbsup' then 'thumbsdown' else 'thumbsup'

      isAlreadyVoted = $("[data-emoji=#{mutualVote}]").parent().hasClass 'active'
      @addAward awardUrl, mutualVote, no if isAlreadyVoted


  isActive: ($emojiBtn) -> $emojiBtn.hasClass 'active'


  decrementCounter: ($emojiBtn, emoji) ->
    isntNoteBody = $emojiBtn.closest('.note-body').length is 0
    counter = $('.js-counter', $emojiBtn)
    counterNumber = parseInt(counter.text())

    if !isntNoteBody
      # If this is a note body, we just hide the award emoji row like the initial state
      $emojiBtn.closest('.js-awards-block').addClass 'hidden'

    if counterNumber > 1
      counter.text(counterNumber - 1)
      @removeMeFromUserList($emojiBtn, emoji)
    else if (emoji == 'thumbsup' || emoji == 'thumbsdown') && isntNoteBody
      $emojiBtn.tooltip('destroy')
      counter.text('0')
      @removeMeFromUserList($emojiBtn, emoji)
    else
      $emojiBtn.tooltip('destroy')
      $emojiBtn.remove()

    $emojiBtn.removeClass('active')


  getAwardTooltip: ($awardBlock) ->

    return $awardBlock.attr('data-original-title') or $awardBlock.attr('data-title')


  removeMeFromUserList: ($emojiBtn, emoji) ->

    awardBlock    = $emojiBtn
    originalTitle = @getAwardTooltip awardBlock

    authors = originalTitle.split ', '
    authors.splice authors.indexOf('me'), 1

    newAuthors = authors.join ', '

    awardBlock
      .closest '.js-emoji-btn'
      .removeData 'original-title'
      .removeData 'title'
      .attr 'data-original-title', newAuthors
      .attr 'data-title', newAuthors

    @resetTooltip(awardBlock)


  addMeToUserList: (emoji) ->

    awardBlock = @findEmojiIcon(emoji).parent()
    origTitle  = @getAwardTooltip awardBlock
    users      = []

    if origTitle
      users = origTitle.trim().split(', ')

    users.push('me')
    awardBlock.attr('title', users.join(', '))

    @resetTooltip(awardBlock)


  resetTooltip: (award) ->
    award.tooltip('destroy')

    # 'destroy' call is asynchronous and there is no appropriate callback on it, this is why we need to set timeout.
    setTimeout (->
      award.tooltip()
    ), 200


  createEmoji_: (emoji) ->

    emojiCssClass = @resolveNameToCssClass emoji

    buttonHtml = "<button class='btn award-control js-emoji-btn has-tooltip active' title='me' data-placement='bottom'>
      <div class='icon emoji-icon #{emojiCssClass}' data-emoji='#{emoji}'></div>
      <span class='award-control-text js-counter'>1</span>
    </button>"

    emoji_node = $(buttonHtml)
      .insertBefore '.js-awards-block .js-award-holder:not(.js-award-action-btn)'
      .find '.emoji-icon'
      .data 'emoji', emoji

    $('.award-control').tooltip()

    $currentBlock = $ '.js-awards-block'

    if $currentBlock.is '.hidden'
      $currentBlock.removeClass 'hidden'


  createEmoji: (emoji) ->

    return @createEmoji_ emoji if $('.emoji-menu').length

    awardMenuUrl = gl.awardMenuUrl or '/emojis'
    @createEmojiMenu awardMenuUrl, => @createEmoji emoji


  resolveNameToCssClass: (emoji) ->

    emoji_icon = $(".emoji-menu-content [data-emoji='#{emoji}']")

    if emoji_icon.length > 0
      unicodeName = emoji_icon.data('unicode-name')
    else
      # Find by alias
      unicodeName = $(".emoji-menu-content [data-aliases*=':#{emoji}:']").data('unicode-name')

    return "emoji-#{unicodeName}"


  postEmoji: (awardUrl, emoji, callback) ->
    $.post awardUrl, { name: emoji }, (data) ->
      if data.ok
        callback.call()

  findEmojiIcon: (emoji) ->
    $(".js-awards-block.awards > .js-emoji-btn [data-emoji='#{emoji}']")

  scrollToAwards: ->
    $('body, html').animate({
      scrollTop: $('.awards').offset().top - 80
    }, 200)

  normilizeEmojiName: (emoji) ->
    @aliases[emoji] || emoji

  addEmojiToFrequentlyUsedList: (emoji) ->
    frequently_used_emojis = @getFrequentlyUsedEmojis()
    frequently_used_emojis.push(emoji)
    $.cookie('frequently_used_emojis', frequently_used_emojis.join(','), { expires: 365 })

  getFrequentlyUsedEmojis: ->
    frequently_used_emojis = ($.cookie('frequently_used_emojis') || '').split(',')
    _.compact(_.uniq(frequently_used_emojis))

  renderFrequentlyUsedBlock: ->
    if $.cookie('frequently_used_emojis')
      frequently_used_emojis = @getFrequentlyUsedEmojis()

      ul = $("<ul class='clearfix emoji-menu-list'>")

      for emoji in frequently_used_emojis
        $(".emoji-menu-content [data-emoji='#{emoji}']").closest('li').clone().appendTo(ul)

      $('input.emoji-search').after(ul).after($('<h5>').text('Frequently used'))

  setupSearch: ->
    $('input.emoji-search').on 'keyup', (ev) =>
      term = $(ev.target).val()

      # Clean previous search results
      $('ul.emoji-menu-search, h5.emoji-search').remove()

      if term
        # Generate a search result block
        h5 = $('<h5>').text('Search results').addClass('emoji-search')
        found_emojis = @searchEmojis(term).show()
        ul = $('<ul>').addClass('emoji-menu-list emoji-menu-search').append(found_emojis)
        $('.emoji-menu-content ul, .emoji-menu-content h5').hide()
        $('.emoji-menu-content').append(h5).append(ul)
      else
        $('.emoji-menu-content').children().show()

  searchEmojis: (term)->
    $(".emoji-menu-content [data-emoji*='#{term}']").closest('li').clone()
