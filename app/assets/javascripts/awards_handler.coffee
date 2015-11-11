class @AwardsHandler
  constructor: (@post_emoji_url, @noteable_type, @noteable_id) ->

  addAward: (emoji) ->
    @postEmoji emoji, =>
      if @exist(emoji)
        if @isActive(emoji)
          @decrementCounter(emoji)
        else
          counter = $(".icon." + emoji).siblings(".counter")
          counter.text(parseInt(counter.text()) + 1)
          counter.parent().addClass("active")
      else
        @createEmoji(emoji)
    

  exist: (emoji) ->
    $(".icon").hasClass(emoji)

  isActive: (emoji) ->
    $(".icon." + emoji).parent().hasClass("active")

  decrementCounter: (emoji) ->
    counter = $(".icon." + emoji).siblings(".counter")

    if parseInt(counter.text()) > 1
      counter.text(parseInt(counter.text()) - 1)
      counter.parent().removeClass("active")
    else
      counter.parent().remove()


  createEmoji: (emoji) ->
    nodes = []
    nodes.push("<div class='award active'>")
    nodes.push("<div class='icon " + emoji + "'>")
    nodes.push(@getImage(emoji))
    nodes.push("</div>")
    nodes.push("<div class='counter'>1")
    nodes.push("</div></div>")

    $(".awards").append(nodes.join("\n"))

  getImage: (emoji) ->
    $("li." + emoji).html()

  postEmoji: (emoji, callback) ->
    emoji = emoji.replace("emoji-", "")
    $.post @post_emoji_url, {
      emoji: emoji
      noteable_type: @noteable_type
      noteable_id: @noteable_id
    },(data) ->
      if data.ok
        callback.call()