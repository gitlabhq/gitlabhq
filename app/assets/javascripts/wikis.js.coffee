class @Wikis
  constructor: ->
    $('.build-new-wiki').bind "click", (e) ->
      $('[data-error~=slug]').addClass("hidden")
      $('p.hint').show()
      field = $('#new_wiki_path')
      valid_slug_pattern = /^[\w\/-]+$/

      slug = field.val()
      if slug.match valid_slug_pattern
        path = field.attr('data-wikis-path')
        if(slug.length > 0)
          location.href = path + "/" + slug
      else
        e.preventDefault()
        $('p.hint').hide()
        $('[data-error~=slug]').removeClass("hidden")
