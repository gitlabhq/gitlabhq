class @AwardsHandler
  constructor: (@post_emoji_url, @noteable_type, @noteable_id) ->

  addAward: (emoji) ->
    @postEmoji emoji, =>
      @addAwardToEmojiBar(emoji)
    
  addAwardToEmojiBar: (emoji) ->
    if @exist(emoji)
      if @isActive(emoji)
        @decrementCounter(emoji)
      else
        counter = @findEmojiIcon(emoji).siblings(".counter")
        counter.text(parseInt(counter.text()) + 1)
        counter.parent().addClass("active")
    else
      @createEmoji(emoji)

  exist: (emoji) ->
    @findEmojiIcon(emoji).length > 0

  isActive: (emoji) ->
    @findEmojiIcon(emoji).parent().hasClass("active")

  decrementCounter: (emoji) ->
    counter = @findEmojiIcon(emoji).siblings(".counter")

    if parseInt(counter.text()) > 1
      counter.text(parseInt(counter.text()) - 1)
      counter.parent().removeClass("active")
    else
      counter.parent().remove()


  createEmoji: (emoji) ->
    nodes = []
    nodes.push("<div class='award active'>")
    nodes.push("<div class='icon' data-emoji='" + emoji + "'>")
    nodes.push(@getImage(emoji))
    nodes.push("</div>")
    nodes.push("<div class='counter'>1")
    nodes.push("</div></div>")

    $(".awards-controls").before(nodes.join("\n"))

  getImage: (emoji) ->
    $("li[data-emoji='" + emoji + "'").html()

  postEmoji: (emoji, callback) ->
    $.post @post_emoji_url, {
      emoji: emoji
      noteable_type: @noteable_type
      noteable_id: @noteable_id
    },(data) ->
      if data.ok
        callback.call()

  findEmojiIcon: (emoji) ->
    $(".icon[data-emoji='" + emoji + "'")