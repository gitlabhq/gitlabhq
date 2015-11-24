class @AwardsHandler
  constructor: (@post_emoji_url, @noteable_type, @noteable_id) ->

  addAward: (emoji) ->
    @postEmoji emoji, =>
      @addAwardToEmojiBar(emoji)
    
  addAwardToEmojiBar: (emoji, custom_path = '') ->
    if @exist(emoji)
      if @isActive(emoji)
        @decrementCounter(emoji)
      else
        counter = @findEmojiIcon(emoji).siblings(".counter")
        counter.text(parseInt(counter.text()) + 1)
        counter.parent().addClass("active")
        @addMeToAuthorList(emoji)
    else
      @createEmoji(emoji, custom_path)

  exist: (emoji) ->
    @findEmojiIcon(emoji).length > 0

  isActive: (emoji) ->
    @findEmojiIcon(emoji).parent().hasClass("active")

  decrementCounter: (emoji) ->
    counter = @findEmojiIcon(emoji).siblings(".counter")

    if parseInt(counter.text()) > 1
      counter.text(parseInt(counter.text()) - 1)
      counter.parent().removeClass("active")
      @removeMeFromAuthorList(emoji)
    else
      award = counter.parent()
      award.tooltip("destroy")
      award.remove()

  removeMeFromAuthorList: (emoji) ->
    award_block = @findEmojiIcon(emoji).parent()
    authors = award_block.attr("data-original-title").split(", ")
    authors = _.without(authors, "me").join(", ")
    award_block.attr("title", authors)
    @resetTooltip(award_block)

  addMeToAuthorList: (emoji) ->
    award_block = @findEmojiIcon(emoji).parent()
    authors = award_block.attr("data-original-title").split(", ")
    authors.push("me")
    award_block.attr("title", authors.join(", "))
    @resetTooltip(award_block)

  resetTooltip: (award) ->
    award.tooltip("destroy")

    # "destroy" call is asynchronous, this is why we need to set timeout.
    setTimeout (->
      award.tooltip()
    ), 200
    

  createEmoji: (emoji, custom_path) ->
    nodes = []
    nodes.push("<div class='award active' title='me'>")
    nodes.push("<div class='icon' data-emoji='" + emoji + "'>")
    nodes.push(@getImage(emoji, custom_path))
    nodes.push("</div>")
    nodes.push("<div class='counter'>1")
    nodes.push("</div></div>")

    $(".awards-controls").before(nodes.join("\n"))

    $(".award").tooltip()

  getImage: (emoji, custom_path) ->
    if custom_path
      $("<img>").attr({src: custom_path, width: 20, height: 20}).wrap("<div>").parent().html()
    else
      $("li[data-emoji='" + emoji + "']").html()


  postEmoji: (emoji, callback) ->
    $.post @post_emoji_url, { note: {
      note: ":" + emoji + ":"
      noteable_type: @noteable_type
      noteable_id: @noteable_id
    }},(data) ->
      if data.ok
        callback.call()

  findEmojiIcon: (emoji) ->
    $(".icon[data-emoji='" + emoji + "']")