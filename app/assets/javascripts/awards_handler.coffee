class @AwardsHandler
  constructor: ->
    @aliases = emojiAliases()

    $(document)
      .off "click", ".js-add-award"
      .on "click", ".js-add-award", (event) =>
        event.stopPropagation()
        event.preventDefault()

        @showEmojiMenu $(event.currentTarget)

    $("html").on 'click', (event) ->
      if !$(event.target).closest(".emoji-menu").length
        if $(".emoji-menu").is(":visible")
          $(".emoji-menu").removeClass "is-visible"

    $(document)
      .off "click", ".js-emoji-btn"
      .on "click", ".js-emoji-btn", @handleClick

  handleClick: (e) =>
    e.preventDefault()
    $emojiBtn = $(e.currentTarget)
    $votesBlock = $($emojiBtn.closest('.js-award-holder').data('target'))

    if $votesBlock.length is 0
      $votesBlock = $emojiBtn.closest('.js-awards-block')

    $votesBlock.addClass 'js-awards-block-current'
    awardUrl = $votesBlock.data 'award-url'
    emoji = $emojiBtn
      .find(".icon")
      .data "emoji"
    @addAward awardUrl, emoji

  showEmojiMenu: ($addBtn) ->
    if $(".emoji-menu").length
      $holder = $addBtn.closest('.js-award-holder')

      if $holder.find('.emoji-menu').length is 0
        $(".emoji-menu").detach().appendTo $holder

      if $(".emoji-menu").is ".is-visible"
        $(".emoji-menu").removeClass "is-visible"
        $("#emoji_search").blur()
      else
        $(".emoji-menu").addClass "is-visible"
        $("#emoji_search").focus()
    else
      $addBtn.addClass "is-loading"
      $.get $addBtn.data('award-menu-url'), (response) =>
        $addBtn.removeClass "is-loading"
        $addBtn.closest('.js-award-holder').append response

        @renderFrequentlyUsedBlock()

        setTimeout =>
          $(".emoji-menu").addClass "is-visible"
          $("#emoji_search").focus()
          @setupSearch()
        , 200

  addAward: (awardUrl, emoji) ->
    emoji = @normilizeEmojiName(emoji)
    @postEmoji awardUrl, emoji, =>
      @addAwardToEmojiBar(emoji)

      $('.js-awards-block-current').removeClass 'js-awards-block-current'

    $(".emoji-menu").removeClass "is-visible"

  addAwardToEmojiBar: (emoji) ->
    @addEmojiToFrequentlyUsedList(emoji)

    emoji = @normilizeEmojiName(emoji)
    $emojiBtn = @findEmojiIcon(emoji).parent()

    if $emojiBtn.length > 0
      if @isActive($emojiBtn)
        @decrementCounter($emojiBtn, emoji)
      else
        counter = $emojiBtn.siblings(".js-counter")
        counter.text(parseInt(counter.text()) + 1)
        $emojiBtn.addClass("active")
        @addMeToUserList(emoji)
    else
      @createEmoji(emoji)

  isActive: ($emojiBtn) ->
    $emojiBtn.hasClass("active")

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
    else if (emoji == "thumbsup" || emoji == "thumbsdown") && isntNoteBody
      $emojiBtn.tooltip("destroy")
      counter.text('0')
      @removeMeFromUserList($emojiBtn, emoji)
    else
      $emojiBtn.tooltip("destroy")
      $emojiBtn.remove()

    $emojiBtn.removeClass("active")

  removeMeFromUserList: ($emojiBtn, emoji) ->
    award_block = $emojiBtn
    authors = award_block
      .attr("data-original-title")
      .split(", ")
    authors.splice(authors.indexOf("me"),1)
    award_block
      .closest(".js-emoji-btn")
      .attr("data-original-title", authors.join(", "))
    @resetTooltip(award_block)

  addMeToUserList: (emoji) ->
    award_block = @findEmojiIcon(emoji).parent()
    origTitle = award_block.attr("data-original-title").trim()
    users = []
    if origTitle
      users = origTitle.split(', ')
    users.push("me")
    award_block.attr("title", users.join(", "))
    @resetTooltip(award_block)

  resetTooltip: (award) ->
    award.tooltip("destroy")

    # "destroy" call is asynchronous and there is no appropriate callback on it, this is why we need to set timeout.
    setTimeout (->
      award.tooltip()
    ), 200


  createEmoji: (emoji) ->
    emojiCssClass = @resolveNameToCssClass(emoji)

    buttonHtml = "<button class='btn award-control js-emoji-btn has-tooltip active' title='me' data-placement='bottom'>
      <div class='icon emoji-icon #{emojiCssClass}' data-emoji='#{emoji}'></div>
      <span class='award-control-text js-counter'>1</span>
    </button>"

    emoji_node = $(buttonHtml)
      .insertBefore(".js-awards-block-current .js-award-holder:not(.js-award-action-btn)")
      .find(".emoji-icon")
      .data("emoji", emoji)
    $('.award-control').tooltip()

    $currentBlock = $('.js-awards-block-current')
    if $currentBlock.is('.hidden')
      $currentBlock.removeClass 'hidden'

  resolveNameToCssClass: (emoji) ->
    emoji_icon = $(".emoji-menu-content [data-emoji='#{emoji}']")

    if emoji_icon.length > 0
      unicodeName = emoji_icon.data("unicode-name")
    else
      # Find by alias
      unicodeName = $(".emoji-menu-content [data-aliases*=':#{emoji}:']").data("unicode-name")

    "emoji-#{unicodeName}"

  postEmoji: (awardUrl, emoji, callback) ->
    $.post awardUrl, { name: emoji }, (data) ->
      if data.ok
        callback.call()

  findEmojiIcon: (emoji) ->
    $(".js-awards-block-current.awards > .js-emoji-btn [data-emoji='#{emoji}']")

  scrollToAwards: ->
    $('body, html').animate({
      scrollTop: $('.awards').offset().top - 80
    }, 200)

  normilizeEmojiName: (emoji) ->
    @aliases[emoji] || emoji

  addEmojiToFrequentlyUsedList: (emoji) ->
    frequently_used_emojis = @getFrequentlyUsedEmojis()
    frequently_used_emojis.push(emoji)
    $.cookie('frequently_used_emojis', frequently_used_emojis.join(","), { expires: 365 })

  getFrequentlyUsedEmojis: ->
    frequently_used_emojis = ($.cookie('frequently_used_emojis') || "").split(",")
    _.compact(_.uniq(frequently_used_emojis))

  renderFrequentlyUsedBlock: ->
    if $.cookie('frequently_used_emojis')
      frequently_used_emojis = @getFrequentlyUsedEmojis()

      ul = $("<ul class='clearfix emoji-menu-list'>")

      for emoji in frequently_used_emojis
        $(".emoji-menu-content [data-emoji='#{emoji}']").closest("li").clone().appendTo(ul)

      $("input.emoji-search").after(ul).after($("<h5>").text("Frequently used"))

  setupSearch: ->
    $("input.emoji-search").on 'keyup', (ev) =>
      term = $(ev.target).val()

      # Clean previous search results
      $("ul.emoji-menu-search, h5.emoji-search").remove()

      if term
        # Generate a search result block
        h5 = $("<h5>").text("Search results").addClass("emoji-search")
        found_emojis = @searchEmojis(term).show()
        ul = $("<ul>").addClass("emoji-menu-list emoji-menu-search").append(found_emojis)
        $(".emoji-menu-content ul, .emoji-menu-content h5").hide()
        $(".emoji-menu-content").append(h5).append(ul)
      else
        $(".emoji-menu-content").children().show()

  searchEmojis: (term)->
    $(".emoji-menu-content [data-emoji*='#{term}']").closest("li").clone()
