class Wikis
  constructor: ->
    $('.build-new-wiki').bind "click", ->
      field = $('#new_wiki_path')
      slug = field.val()
      path = field.attr('data-wikis-path')

      if(slug.length > 0)
        location.href = path + "/" + slug


@Wikis = Wikis
